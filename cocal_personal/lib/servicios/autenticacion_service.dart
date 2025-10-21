import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AutenticacionService {
  static final _cliente = SupabaseService.cliente;

  /// Registrar usuario en Supabase (Auth + tabla usuario)
  static Future<String?> registrar({
    required String correo,
    required String contrasena,
    required String nombre,
    String? apellido,
  }) async {
    try {
      final respuesta = await _cliente.auth.signUp(
        email: correo,
        password: contrasena,
      );

      final user = respuesta.user;
      if (user == null) return 'Error al registrar usuario';

      final insert = await _cliente.from('usuario').insert({
        'correo': correo,
        'nombre': nombre,
        'apellido': apellido ?? '',
      });

      if (insert.error != null) {
        return insert.error!.message;
      }

      return null; // ✅ Registro exitoso
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Iniciar sesión con correo y contraseña
  static Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final respuesta = await _cliente.auth.signInWithPassword(
        email: correo,
        password: contrasena,
      );

      final user = respuesta.user;
      if (user == null) return 'Credenciales inválidas';
      return null; // ✅ Login exitoso
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Cerrar sesión
  static Future<void> cerrarSesion() async {
    await _cliente.auth.signOut();
  }
}
