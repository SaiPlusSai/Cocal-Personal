import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import 'package:image_picker/image_picker.dart';

class PerfilService {
  static final _db = SupabaseService.cliente;
  static final _auth = SupabaseService.cliente.auth;
  static final _storage = SupabaseService.cliente.storage;

  /// Se asegura de que exista un registro en `usuario`
  /// a partir de los datos de Supabase Auth (signup / login).
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
      final res = await _db.from('usuario').upsert(
        {
          'correo': email,
          'contrasena': '', // NOT NULL, pero realmente no la usas aquí
          'nombre': nombre,
          'apellido': apellido,
          'estado': 'ACTIVO',
          'verificado': user.emailConfirmedAt != null,
          'creado_en': DateTime.now().toIso8601String(),
          'actualizado_en': DateTime.now().toIso8601String(),
        },
        onConflict: 'correo',
      );

      debugPrint('[PERFIL] upsert OK para $email: $res');
    } catch (e) {
      debugPrint('[PERFIL] Error al sincronizar perfil: $e');
    }
  }

  // ==========================
  // OBTENER PERFIL
  // ==========================
  static Future<Map<String, dynamic>?> obtenerPerfilActual() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final email = user.email;
    if (email == null) return null;

    try {
      return await _db
          .from('usuario')
          .select('nombre, apellido, correo, foto_url')
          .eq('correo', email)
          .single();
    } catch (e) {
      debugPrint('[PERFIL] Error al obtener perfil: $e');
      return null;
    }
  }

  // ==========================
  // ACTUALIZAR NOMBRE/APELLIDO
  // ==========================
  static Future<String?> actualizarPerfil({
    required String nombre,
    required String apellido,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'No autenticado';

    try {
      await _auth.updateUser(
        UserAttributes(
          data: {
            'nombre': nombre,
            'apellido': apellido,
          },
        ),
      );

      await _db
          .from('usuario')
          .update({
        'nombre': nombre,
        'apellido': apellido,
        'actualizado_en': DateTime.now().toIso8601String(),
      })
          .eq('correo', user.email!);

      return null;
    } catch (e) {
      return 'Error al actualizar perfil';
    }
  }
  // ==========================
  // SUBIR FOTO DE PERFIL
  // ==========================
  static Future<String?> subirFotoPerfil(XFile imagen) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final bytes = await imagen.readAsBytes();
      final path = 'user_${user.id}.jpg';

      // subir al bucket
      await _storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      // obtener URL pública
      final url = _storage.from('avatars').getPublicUrl(path);

      // guardar en tabla usuario
      await _db
          .from('usuario')
          .update({
        'foto_url': url,
        'actualizado_en': DateTime.now().toIso8601String(),
      })
          .eq('correo', user.email!);

      return url;
    } catch (e) {
      debugPrint('[PERFIL] Error subiendo foto: $e');
      return null;
    }
  }
}
