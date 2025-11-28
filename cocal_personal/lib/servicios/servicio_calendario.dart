//lib/servicios/servicio_calendario.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:flutter/foundation.dart';

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

  /// Lista todos los calendarios que “afectan” al usuario:
  /// - los que creó él (id_usuario)
  /// - los compartidos directo (calendario_compartido_usuario)
  /// - los que ve por grupo (calendario_compartido_grupo + perfil_grupo)
  static Future<List<int>> obtenerCalendariosVisiblesDelUsuario(
      int idUsuario) async {
    final c = SupabaseService.cliente;
    debugPrint('[CAL_SERV] obtenerCalendariosVisiblesDelUsuario → $idUsuario');

    final propios = await c
        .from('calendario')
        .select('id')
        .eq('id_usuario', idUsuario);

    final compartidosDirectos = await c
        .from('calendario_compartido_usuario')
        .select('id_calendario')
        .eq('id_destinatario', idUsuario);

    final grupos = await c
        .from('perfil_grupo')
        .select('id_grupo')
        .eq('id_usuario', idUsuario);

    final gruposList = (grupos as List);
    List compartidosGrupos = [];
    if (gruposList.isNotEmpty) {
      compartidosGrupos = await c
          .from('calendario_compartido_grupo')
          .select('id_calendario, id_grupo')
          .inFilter('id_grupo',
          gruposList.map((g) => g['id_grupo'] as int).toList());
    }

    final ids = <int>{};

    for (final r in (propios as List)) {
      ids.add(r['id'] as int);
    }
    for (final r in (compartidosDirectos as List)) {
      ids.add(r['id_calendario'] as int);
    }
    for (final r in (compartidosGrupos as List)) {
      ids.add(r['id_calendario'] as int);
    }

    debugPrint('[CAL_SERV] calendarios visibles: $ids');
    return ids.toList();
  }


  /// Obtiene todos los eventos del usuario en un rango de fechas
  static Future<List<Map<String, dynamic>>> listarEventosUsuarioEnRango({
    required List<int> idsCalendario,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    if (idsCalendario.isEmpty) return [];

    final res = await _cliente
        .from('evento')
        .select('*')
        .inFilter('id_calendario', idsCalendario)
        .gte('horario', desde.toUtc().toIso8601String())
        .lte('horario', hasta.toUtc().toIso8601String())
        .order('horario', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // lib/servicios/servicio_calendario.dart

  /// Crea un calendario ligado a un grupo (calendario colaborativo).
  static Future<String?> crearCalendarioDeGrupo({
    required int idGrupo,
    required String nombre,
    String zonaHoraria = 'America/La_Paz',
  }) async {
    try {
      // 1) Opcional: dueño del calendario = creador del grupo o usuario actual.
      // Para simplificar, usamos el usuario actual como propietario.
      final authUser = _cliente.auth.currentUser;
      if (authUser == null || authUser.email == null) {
        return 'No hay usuario autenticado';
      }

      final usuarioRow = await _cliente
          .from('usuario')
          .select('id')
          .eq('correo', authUser.email!)
          .maybeSingle();

      if (usuarioRow == null) return 'Usuario no encontrado';

      final idUsuario = usuarioRow['id'] as int;

      // 2) Crear calendario
      final cal = await _cliente
          .from('calendario')
          .insert({
        'id_usuario': idUsuario,
        'nombre': nombre,
        'zona_horaria': zonaHoraria,
      })
          .select('id')
          .single();

      final idCalendario = cal['id'] as int;

      // 3) Asociarlo al grupo (colaborativo)
      await _cliente.from('grupo_calendario').insert({
        'id_calendario': idCalendario,
        'id_grupo': idGrupo,
      });

      // Opcional: también en calendario_compartido_grupo con permisos
      await _cliente.from('calendario_compartido_grupo').insert({
        'id_calendario': idCalendario,
        'id_grupo': idGrupo,
        'permisos': 'EDICION', // o 'LECTURA'
      });

      return null;
    } catch (e) {
      return 'Error al crear calendario colaborativo: $e';
    }
  }

  /// Lista calendarios de un grupo (colaborativos)
  static Future<List<Map<String, dynamic>>> listarCalendariosDeGrupo(
      int idGrupo) async {
    try {
      final res = await _cliente
          .from('grupo_calendario')
          .select('id_calendario, calendario (id, nombre, zona_horaria)')
          .eq('id_grupo', idGrupo);

      final List<Map<String, dynamic>> out = [];
      for (final row in (res as List)) {
        final cal = row['calendario'] as Map<String, dynamic>?;
        if (cal != null) out.add(cal);
      }
      return out;
    } catch (e) {
      return [];
    }
  }
  /// Eventos de todos los miembros de un grupo en un rango
  static Future<List<Map<String, dynamic>>> listarEventosDeGrupoEnRango({
    required int idGrupo,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    // 1) miembros del grupo
    final miembros = await _cliente
        .from('perfil_grupo')
        .select('id_usuario')
        .eq('id_grupo', idGrupo);

    final idsMiembros = (miembros as List)
        .map((m) => m['id_usuario'] as int)
        .toList();

    if (idsMiembros.isEmpty) return [];

    // 2) calendarios de esos usuarios
    final cals = await _cliente
        .from('calendario')
        .select('id, id_usuario')
        .inFilter('id_usuario', idsMiembros);

    final idsCalendarios = (cals as List)
        .map((c) => c['id'] as int)
        .toList();

    if (idsCalendarios.isEmpty) return [];

    // 3) eventos en esos calendarios
    final eventos = await _cliente
        .from('evento')
        .select('id, titulo, horario, id_calendario')
        .inFilter('id_calendario', idsCalendarios)
        .gte('horario', desde.toUtc().toIso8601String())
        .lte('horario', hasta.toUtc().toIso8601String());

    // Enriquecemos con id_usuario para poder contar por persona
    final mapaCalToUser = <int, int>{};
    for (final c in cals) {
      mapaCalToUser[c['id'] as int] = c['id_usuario'] as int;
    }

    return (eventos as List).map<Map<String, dynamic>>((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final idCal = map['id_calendario'] as int;
      map['id_usuario'] = mapaCalToUser[idCal];
      return map;
    }).toList();
  }



}
