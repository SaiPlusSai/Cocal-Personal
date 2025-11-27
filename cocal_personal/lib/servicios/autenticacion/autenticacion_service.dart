// cocal_personal/lib/servicios/autenticacion/autenticacion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import 'perfil_service.dart';

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
      print('[AUTH] signUp → $correo');
      final res = await _auth.signUp(
        email: correo,
        password: contrasena,
        data: {'nombre': nombre, 'apellido': apellido},
        emailRedirectTo: _mobileRedirect,
      );

      print('[AUTH] signUp result user: ${res.user}, session: ${res.session}');
      return null;
    } on AuthException catch (e) {
      print('[AUTH] AuthException: ${e.message}');
      return e.message;
    } catch (e) {
      print('[AUTH] Exception: $e');
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

      // 👇 después de loguear, sincronizamos perfil en la tabla `usuario`
      await PerfilService.ensurePerfilDesdeAuth();

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

  /// Reenviar correo de verificación de signup
  static Future<String?> reenviarVerificacion(String correo) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: correo,
        emailRedirectTo: _mobileRedirect,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al reenviar verificación: $e';
    }
  }
}
