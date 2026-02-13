import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de autenticación con Google para acceso a Google Drive.
/// Usa el scope drive.appdata para acceso exclusivo a la carpeta oculta de la app.
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'google_access_token';

  static GoogleSignInAccount? _currentUser;

  /// Usuario actualmente logueado
  static GoogleSignInAccount? get currentUser => _currentUser;

  /// Verifica si hay una sesión activa
  static bool get isSignedIn => _currentUser != null;

  /// Email del usuario conectado
  static String? get userEmail => _currentUser?.email;

  /// Intenta restaurar la sesión silenciosamente al abrir la app
  static Future<bool> trySilentSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        debugPrint('✅ Google Sign-In silencioso exitoso: ${_currentUser!.email}');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Error en sign-in silencioso: $e');
    }
    return false;
  }

  /// Inicia sesión interactiva con Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        debugPrint('✅ Google Sign-In exitoso: ${_currentUser!.email}');
        // Guardar token de forma segura
        final auth = await _currentUser!.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.write(key: _tokenKey, value: auth.accessToken);
        }
      }
      return _currentUser;
    } catch (e) {
      debugPrint('❌ Error en Google Sign-In: $e');
      rethrow;
    }
  }

  /// Cierra la sesión de Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: _tokenKey);
      _currentUser = null;
      debugPrint('✅ Google Sign-Out exitoso');
    } catch (e) {
      debugPrint('❌ Error en Google Sign-Out: $e');
      rethrow;
    }
  }

  /// Desconecta completamente la cuenta (revoca acceso)
  static Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await _secureStorage.delete(key: _tokenKey);
      _currentUser = null;
      debugPrint('✅ Google Disconnect exitoso');
    } catch (e) {
      debugPrint('❌ Error en Google Disconnect: $e');
      rethrow;
    }
  }

  /// Obtiene headers de autenticación para llamadas a la API de Drive
  static Future<Map<String, String>?> getAuthHeaders() async {
    if (_currentUser == null) {
      // Intentar restaurar sesión
      final restored = await trySilentSignIn();
      if (!restored) return null;
    }

    try {
      final headers = await _currentUser!.authHeaders;
      return headers;
    } catch (e) {
      debugPrint('❌ Error obteniendo auth headers: $e');
      // Intentar re-autenticar
      try {
        _currentUser = await _googleSignIn.signInSilently(reAuthenticate: true);
        if (_currentUser != null) {
          return await _currentUser!.authHeaders;
        }
      } catch (e2) {
        debugPrint('❌ Error re-autenticando: $e2');
      }
      return null;
    }
  }
}
