import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'supabase_service.dart';

class AutenticacionService {
  static final _cliente = SupabaseService.cliente;

  static Future<String?> registrar({
    required String correo,
    required String contrasena,
    required String nombre,
    String? apellido,
  }) async {
    try {
      final existente = await _cliente
          .from('usuario')
          .select('id')
          .eq('correo', correo)
          .maybeSingle();

      if (existente != null && existente.isNotEmpty) {
        return 'El correo ya está registrado';
      }

      final hash = sha256.convert(utf8.encode(contrasena)).toString();

      await _cliente.from('usuario').insert({
        'correo': correo,
        'contrasena': hash,
        'nombre': nombre,
        'apellido': apellido ?? '',
      });

      return null;
    } catch (e) {
      return 'Error al registrar: $e';
    }
  }

  static Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final res = await _cliente
          .from('usuario')
          .select('contrasena, nombre')
          .eq('correo', correo)
          .maybeSingle();

      if (res == null) {
        return 'Usuario no encontrado';
      }

      final hash = sha256.convert(utf8.encode(contrasena)).toString();

      if (res['contrasena'] != hash) {
        return 'Contraseña incorrecta';
      }

      return null;
    } catch (e) {
      return 'Error al iniciar sesión: $e';
    }
  }

  static Future<void> cerrarSesion() async {
    // No hay sesión activa, pero se puede limpiar almacenamiento local si luego usás SharedPreferences
  }
}
