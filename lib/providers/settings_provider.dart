import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/backup_settings.dart';
import '../services/google_auth_service.dart';
import '../services/backup_service.dart';

/// Provider para gestionar la configuración de backup y cuenta de Google
class SettingsProvider with ChangeNotifier {
  static const String _settingsBoxName = 'backup_settings';

  BackupSettings _settings = BackupSettings();
  bool _isLoading = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _errorMessage;
  List<BackupInfo> _backups = [];

  BackupSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;
  List<BackupInfo> get backups => _backups;
  bool get isGoogleConnected => GoogleAuthService.isSignedIn;
  String? get googleEmail => GoogleAuthService.userEmail;

  SettingsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Registrar TypeAdapter si no está registrado
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(BackupSettingsAdapter());
      }

      // Abrir box de configuración
      final box = await Hive.openBox<BackupSettings>(_settingsBoxName);

      // Cargar o crear configuración
      _settings = box.get('settings') ?? BackupSettings();
      if (!box.containsKey('settings')) {
        await box.put('settings', _settings);
      }

      // Intentar restaurar sesión de Google silenciosamente
      await GoogleAuthService.trySilentSignIn();
      if (GoogleAuthService.isSignedIn) {
        _settings.googleEmail = GoogleAuthService.userEmail;
        await _saveSettings();
      }

      // Verificar si hay backup pendiente
      if (_settings.isBackupPending && GoogleAuthService.isSignedIn) {
        debugPrint('📋 Backup pendiente detectado, ejecutando...');
        await performBackup(silent: true);
      }
    } catch (e) {
      debugPrint('❌ Error inicializando SettingsProvider: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guarda la configuración en Hive
  Future<void> _saveSettings() async {
    try {
      final box = Hive.box<BackupSettings>(_settingsBoxName);
      await box.put('settings', _settings);
    } catch (e) {
      debugPrint('❌ Error guardando configuración: $e');
    }
  }

  /// Conectar cuenta de Google
  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final account = await GoogleAuthService.signIn();
      if (account != null) {
        _settings.googleEmail = account.email;
        await _saveSettings();

        // Comprobar si ya existen backups (instalación anterior)
        await loadBackups();

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error al conectar con Google: $e';
      debugPrint('❌ $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Desconectar cuenta de Google
  Future<void> signOutGoogle({bool deleteRemoteBackups = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (deleteRemoteBackups) {
        // Eliminar todos los backups antes de desconectar
        final allBackups = await BackupService.listBackups();
        for (final backup in allBackups) {
          await BackupService.deleteBackup(backup.id);
        }
      }

      await GoogleAuthService.signOut();
      _settings.googleEmail = null;
      _settings.autoBackupEnabled = false;
      await _saveSettings();
      _backups = [];
    } catch (e) {
      _errorMessage = 'Error al desconectar: $e';
      debugPrint('❌ $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar lista de backups desde Drive
  Future<void> loadBackups() async {
    try {
      _backups = await BackupService.listBackups();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error cargando lista de backups: $e');
    }
  }

  /// Realizar backup manual o automático
  Future<bool> performBackup({bool silent = false}) async {
    if (_isBackingUp) return false;

    _isBackingUp = true;
    _errorMessage = null;
    if (!silent) notifyListeners();

    try {
      final success = await BackupService.createBackup();

      if (success) {
        _settings.lastBackupDate = DateTime.now();
        await _saveSettings();

        // Eliminar backups antiguos si excede el máximo
        await BackupService.pruneBackups(_settings.maxBackupCount);

        // Recargar lista
        await loadBackups();
      } else {
        _errorMessage = 'No se pudo crear el backup';
      }

      _isBackingUp = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error durante el backup: $e';
      debugPrint('❌ $_errorMessage');
      _isBackingUp = false;
      notifyListeners();
      return false;
    }
  }

  /// Restaurar un backup desde Drive
  Future<bool> restoreBackup(String fileId, {bool createSafetyBackup = true}) async {
    if (_isRestoring) return false;

    _isRestoring = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Crear backup de seguridad antes de restaurar
      if (createSafetyBackup) {
        debugPrint('🔒 Creando backup de seguridad antes de restaurar...');
        await BackupService.createBackup();
      }

      // Restaurar el backup seleccionado
      final success = await BackupService.restoreBackup(fileId);

      if (!success) {
        _errorMessage = 'No se pudo restaurar el backup';
      }

      _isRestoring = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error durante la restauración: $e';
      debugPrint('❌ $_errorMessage');
      _isRestoring = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar configuración de backup automático
  Future<void> setAutoBackupEnabled(bool enabled) async {
    _settings.autoBackupEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Actualizar hora del backup
  Future<void> setBackupTime(int hour, int minute) async {
    _settings.backupHour = hour;
    _settings.backupMinute = minute;
    await _saveSettings();
    notifyListeners();
  }

  /// Actualizar máximo de copias
  Future<void> setMaxBackupCount(int count) async {
    _settings.maxBackupCount = count.clamp(1, 30);
    await _saveSettings();
    notifyListeners();
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
