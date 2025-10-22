import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ServicioCalendario {
  static final _cliente = SupabaseService.cliente;

  /// Obtiene el id de usuario a partir del correo.
  static Future<int?> obtenerUsuarioIdPorCorreo(String correo) async {
    try {
      final res = await _cliente
          .from('usuario')
          .select('id')
          .eq('correo', correo)
          .maybeSingle();

      if (res == null) return null;
      return res['id'] as int;
    } catch (e) {
      return null;
    }
  }

  /// Lista todos los calendarios del usuario (por id_usuario).
  static Future<List<Map<String, dynamic>>> listarCalendariosDeUsuario(int idUsuario) async {
    try {
      final res = await _cliente
          .from('calendario')
          .select('id, nombre, zona_horaria, creado_en')
          .eq('id_usuario', idUsuario)
          .order('creado_en', ascending: false);

      // `res` ya es una lista de mapas en Supabase v2
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Crea un calendario para el usuario.
  static Future<String?> crearCalendario({
    required int idUsuario,
    required String nombre,
    String zonaHoraria = 'America/La_Paz',
  }) async {
    try {
      await _cliente.from('calendario').insert({
        'id_usuario': idUsuario,
        'nombre': nombre,
        'zona_horaria': zonaHoraria,
      });
      return null; // OK
    } catch (e) {
      return 'Error al crear calendario: $e';
    }
  }

  /// Elimina un calendario por id (y en cascada sus eventos si la FK está ON DELETE CASCADE).
  static Future<String?> eliminarCalendario(int idCalendario) async {
    try {
      await _cliente.from('calendario').delete().eq('id', idCalendario);
      return null; // OK
    } catch (e) {
      return 'Error al eliminar calendario: $e';
    }
  }
}
