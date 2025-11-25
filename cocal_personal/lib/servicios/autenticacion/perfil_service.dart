// lib/servicios/autenticacion/perfil_service.dart
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';

class PerfilService {
  static final _db = SupabaseService.cliente;
  static final _auth = SupabaseService.cliente.auth;

  static Future<void> ensurePerfilDesdeAuth() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[PERFIL] No hay usuario autenticado, nada que sincronizar');
      return;
    }

    final email = user.email ?? '';
    final meta = user.userMetadata ?? {};
    final nombre = (meta['nombre'] ?? '').toString();
    final apellido = (meta['apellido'] ?? '').toString();

    if (email.isEmpty) {
      debugPrint('[PERFIL] Usuario sin email, no se puede sincronizar');
      return;
    }

    try {
      final res = await _db
          .from('usuario')
          .upsert({
        'correo': email,
        'contrasena': '', // 👈 para cumplir NOT NULL
        'nombre': nombre,
        'apellido': apellido,
        'estado': 'ACTIVO', // si ese es el valor por defecto
        'verificado': user.emailConfirmedAt != null,
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      }, onConflict: 'correo'); // evita duplicado por correo

      debugPrint('[PERFIL] upsert OK para $email: $res');
    } catch (e) {
      debugPrint('[PERFIL] Error al sincronizar perfil: $e');
    }
  }
}
