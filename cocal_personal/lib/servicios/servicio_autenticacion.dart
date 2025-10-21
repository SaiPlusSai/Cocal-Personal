import 'package:supabase_flutter/supabase_flutter.dart';

final _cliente = Supabase.instance.client;

class ServicioAutenticacion {
  /// Registrar usuario
  static Future<String?> registrar({
    required String email,
    required String password,
    required String nombre,
    String? apellido,
  }) async {
    try {
      final AuthResponse res = await _cliente.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) return 'No se pudo crear el usuario.';

      await _cliente.from('usuario').insert({
        'correo': email,
        'nombre': nombre,
        'apellido': apellido ?? '',
      });

      return null; // OK
    } on AuthException catch (e) {
      return e.message;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// Iniciar sesión
  static Future<String?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _cliente.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) return 'Usuario o contraseña inválidos';
      return null; // OK
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// Cerrar sesión
  static Future<void> cerrarSesion() async {
    try {
      await _cliente.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }
}
