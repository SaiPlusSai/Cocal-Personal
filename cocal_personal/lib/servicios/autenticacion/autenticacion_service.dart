// cocal_personal/lib/servicios/autenticacion/autenticacion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';

class AutenticacionService {
  static final _auth = SupabaseService.cliente.auth;

  static const _mobileRedirect = 'cocal://auth-callback';

  /// REGISTRO con Supabase Auth
  static Future<String?> registrar({
    required String correo,
    required String contrasena,
    String? nombre,
    String? apellido,
  }) async {
    try {
      await _auth.signUp(
        email: correo,
        password: contrasena,
        data: {'nombre': nombre, 'apellido': apellido},
        emailRedirectTo: _mobileRedirect, // deep link de verificación
      );
      return null; // OK (si Confirm Email está ON, no habrá sesión aún)
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error de registro: $e';
    }
  }

  /// LOGIN (email + password)
  static Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _auth.signInWithPassword(email: correo, password: contrasena);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al iniciar sesión: $e';
    }
  }

  static Future<void> cerrarSesion() => _auth.signOut();

  /// Enviar correo de recuperación
  static Future<String?> solicitarRecuperacion(String correo) async {
    try {
      await _auth.resetPasswordForEmail(
        correo,
        redirectTo: _mobileRedirect,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al solicitar recuperación: $e';
    }
  }

  /// Actualiza contraseña tras abrir el link de recovery (sesión temporal)
  static Future<String?> actualizarPassword(String nueva) async {
    try {
      await _auth.updateUser(UserAttributes(password: nueva));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al actualizar contraseña: $e';
    }
  }
}
