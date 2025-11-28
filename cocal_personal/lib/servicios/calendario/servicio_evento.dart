// lib/servicios/calendario/servicio_evento.dart
import '../supabase_service.dart';

class ServicioEvento {
  static final _cliente = SupabaseService.cliente;

  /// Lista eventos de UN calendario
  static Future<List<Map<String, dynamic>>> listarEventosDeCalendario(
      int idCalendario) async {
    final res = await _cliente
        .from('evento')
        .select('*')
        .eq('id_calendario', idCalendario)
        .order('horario', ascending: true);

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Crear evento y devolver la fila creada
  static Future<Map<String, dynamic>> crearEvento({
    required String titulo,
    String? descripcion,
    required DateTime horario,
    required String tema,
    required String estado,
    required String visibilidad,
    required int idCalendario,
    required String creador,
  }) async {
    final res = await _cliente
        .from('evento')
        .insert({
      'titulo': titulo,
      'descripcion': descripcion,
      'horario': horario.toIso8601String(),
      'tema': tema,
      'estado': estado,
      'visibilidad': visibilidad,
      'id_calendario': idCalendario,
      'creador': creador,
    })
        .select('*') // puedes reducir a 'id, titulo, horario' si quieres
        .single();

    return Map<String, dynamic>.from(res as Map);
  }

  /// Eliminar evento
  static Future<void> eliminarEvento(int id) async {
    await _cliente.from('evento').delete().eq('id', id);
  }

  /// Actualizar solo recordatorio
  static Future<void> actualizarRecordatorio({
    required int idEvento,
    required int minutos,
  }) async {
    await _cliente
        .from('evento')
        .update({'recordatorio_minutos': minutos}).eq('id', idEvento);
  }
}

