import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/frequency.dart';
import 'google_auth_service.dart';
import 'database_service.dart';

/// Información de un archivo de backup en Google Drive
class BackupInfo {
  final String id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;

  BackupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get dateFormatted => DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
}

/// Servicio de backup y restauración de la base de datos Hive en Google Drive.
/// Usa la carpeta appDataFolder (oculta, solo accesible por esta app).
class BackupService {
  static const String _driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const String _driveUploadBase = 'https://www.googleapis.com/upload/drive/v3';
  static const String _backupPrefix = 'lifeplan_backup_';
  static const Duration _timeout = Duration(seconds: 60);

  /// Crea un backup de la base de datos y lo sube a Google Drive.
  /// Retorna true si fue exitoso.
  static Future<bool> createBackup() async {
    final headers = await GoogleAuthService.getAuthHeaders();
    if (headers == null) {
      debugPrint('❌ No se pudo obtener autenticación para backup');
      return false;
    }

    try {
      // 1. Exportar los datos de Hive a JSON
      final jsonData = await _exportDatabaseToJson();

      // 2. Generar nombre del archivo con timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = '$_backupPrefix$timestamp.json';

      // 3. Subir a Google Drive (appDataFolder)
      final success = await _uploadToDrive(headers, fileName, jsonData);

      if (success) {
        debugPrint('✅ Backup creado exitosamente: $fileName');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error creando backup: $e');
      return false;
    }
  }

  /// Lista los backups disponibles en Google Drive
  static Future<List<BackupInfo>> listBackups() async {
    final headers = await GoogleAuthService.getAuthHeaders();
    if (headers == null) return [];

    try {
      final uri = Uri.parse(
        '$_driveApiBase/files?spaces=appDataFolder'
        '&q=name contains \'$_backupPrefix\''
        '&fields=files(id,name,createdTime,size)'
        '&orderBy=createdTime desc'
        '&pageSize=50',
      );

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('❌ Error listando backups: ${response.statusCode} ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body);
      final files = (data['files'] as List?) ?? [];

      return files.map((f) => BackupInfo(
        id: f['id'] as String,
        name: f['name'] as String,
        createdAt: DateTime.parse(f['createdTime'] as String),
        sizeBytes: int.tryParse(f['size']?.toString() ?? '0') ?? 0,
      )).toList();
    } catch (e) {
      debugPrint('❌ Error listando backups: $e');
      return [];
    }
  }

  /// Restaura un backup desde Google Drive
  static Future<bool> restoreBackup(String fileId) async {
    final headers = await GoogleAuthService.getAuthHeaders();
    if (headers == null) return false;

    try {
      // 1. Descargar el archivo de Drive
      final uri = Uri.parse('$_driveApiBase/files/$fileId?alt=media');
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('❌ Error descargando backup: ${response.statusCode}');
        return false;
      }

      final jsonData = response.body;

      // 2. Validar que es un JSON válido
      final parsed = jsonDecode(jsonData);
      if (parsed is! Map || !parsed.containsKey('goals')) {
        debugPrint('❌ Archivo de backup no válido');
        return false;
      }

      // 3. Restaurar datos en Hive
      await _importDatabaseFromJson(jsonData);

      debugPrint('✅ Backup restaurado exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error restaurando backup: $e');
      return false;
    }
  }

  /// Elimina un backup de Google Drive
  static Future<bool> deleteBackup(String fileId) async {
    final headers = await GoogleAuthService.getAuthHeaders();
    if (headers == null) return false;

    try {
      final uri = Uri.parse('$_driveApiBase/files/$fileId');
      final response = await http.delete(uri, headers: headers).timeout(_timeout);

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error eliminando backup: $e');
      return false;
    }
  }

  /// Elimina los backups más antiguos si se supera el máximo permitido
  static Future<void> pruneBackups(int maxCount) async {
    final backups = await listBackups();
    if (backups.length <= maxCount) return;

    // Los backups ya vienen ordenados por fecha desc, eliminar los más antiguos
    final toDelete = backups.sublist(maxCount);
    for (final backup in toDelete) {
      await deleteBackup(backup.id);
      debugPrint('🗑️ Backup antiguo eliminado: ${backup.name}');
    }
  }

  /// Exporta toda la base de datos Hive a JSON
  static Future<String> _exportDatabaseToJson() async {
    final goals = DatabaseService.getAllGoals();
    final goalsJson = goals.map((goal) => {
      'id': goal.id,
      'title': goal.title,
      'category': goal.category,
      'frequency': goal.frequency.index,
      'createdDate': goal.createdDate.toIso8601String(),
      'records': goal.records.map((key, value) => MapEntry(key, value)),
      'orderIndex': goal.orderIndex,
    }).toList();

    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'goals': goalsJson,
    };

    return jsonEncode(backup);
  }

  /// Importa datos desde JSON a la base de datos Hive
  static Future<void> _importDatabaseFromJson(String jsonData) async {
    final data = jsonDecode(jsonData);
    final goalsData = data['goals'] as List;

    // Limpiar datos actuales
    await DatabaseService.clearAllData();

    // Importar cada goal
    for (var index = 0; index < goalsData.length; index++) {
      final goalJson = goalsData[index];
      final records = <String, bool>{};
      if (goalJson['records'] != null) {
        (goalJson['records'] as Map<String, dynamic>).forEach((key, value) {
          records[key] = value as bool;
        });
      }

      final goal = Goal(
        id: goalJson['id'] as String,
        title: goalJson['title'] as String,
        category: goalJson['category'] as String,
        frequency: Frequency.values[goalJson['frequency'] as int],
        createdDate: DateTime.parse(goalJson['createdDate'] as String),
        records: records,
        orderIndex: (goalJson['orderIndex'] as int?) ?? index,
      );

      await DatabaseService.addGoal(goal);
    }
  }

  /// Sube un archivo a Google Drive en la carpeta appDataFolder
  static Future<bool> _uploadToDrive(
    Map<String, String> authHeaders,
    String fileName,
    String content,
  ) async {
    try {
      // Usar multipart upload para incluir metadatos y contenido
      final metadata = jsonEncode({
        'name': fileName,
        'parents': ['appDataFolder'],
      });

      final uri = Uri.parse('$_driveUploadBase/files?uploadType=multipart');

      // Crear request multipart
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(authHeaders);

      // Parte 1: Metadatos JSON
      request.files.add(http.MultipartFile.fromString(
        'metadata',
        metadata,
        contentType: http.MediaType('application', 'json'),
      ));

      // Parte 2: Contenido del archivo
      request.files.add(http.MultipartFile.fromString(
        'media',
        content,
        contentType: http.MediaType('application', 'json'),
      ));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      debugPrint('❌ Error subiendo a Drive: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ Error en upload a Drive: $e');
      return false;
    }
  }
}
