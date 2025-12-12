// lib/servicios/calendario/servicio_calendario.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_service.dart';
import 'modelos/calendario_model.dart';
import 'modelos/evento_model.dart';

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
  static Future<List<Map<String, dynamic>>> listarCalendariosDeUsuario(
      int idUsuario) async {
    try {
      final res = await _cliente
          .from('calendario')
          .select('id, nombre, zona_horaria, creado_en')
          .eq('id_usuario', idUsuario)
          .order('creado_en', ascending: false);

      return List<Map<String, dynamic>>.from(res as List);
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

  /// Elimina un calendario por id.
  static Future<String?> eliminarCalendario(int idCalendario) async {
    try {
      await _cliente.from('calendario').delete().eq('id', idCalendario);
      return null; // OK
    } catch (e) {
      return 'Error al eliminar calendario: $e';
    }
  }

  /// Lista todos los calendarios que afectan al usuario.
  static Future<List<int>> obtenerCalendariosVisiblesDelUsuario(
      int idUsuario) async {
    final c = SupabaseService.cliente;
    debugPrint('[CAL_SERV] obtenerCalendariosVisiblesDelUsuario → $idUsuario');

    final propios =
    await c.from('calendario').select('id').eq('id_usuario', idUsuario);

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
          .inFilter(
        'id_grupo',
        gruposList.map((g) => g['id_grupo'] as int).toList(),
      );
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

  /// Obtiene todos los eventos del usuario en un rango de fechas.
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

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Crea un calendario ligado a un grupo (colaborativo).
  static Future<String?> crearCalendarioDeGrupo({
    required int idGrupo,
    required String nombre,
    String zonaHoraria = 'America/La_Paz',
  }) async {
    try {
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

      await _cliente.from('grupo_calendario').insert({
        'id_calendario': idCalendario,
        'id_grupo': idGrupo,
      });

      await _cliente.from('calendario_compartido_grupo').insert({
        'id_calendario': idCalendario,
        'id_grupo': idGrupo,
        'permisos': 'EDICION',
      });

      return null;
    } catch (e) {
      return 'Error al crear calendario colaborativo: $e';
    }
  }

  /// Lista calendarios de un grupo (colaborativos).
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
  /// Devuelve el calendario PRINCIPAL del grupo.
  /// Si no existe, lo crea y lo vincula al grupo.
  static Future<CalendarioModel?> obtenerOCrearCalendarioDeGrupo(
      int idGrupo, {
        String? nombre,
      }) async {
    try {
      // 1) ¿Ya hay calendarios asociados al grupo?
      final existentes = await listarCalendariosDeGrupo(idGrupo);

      if (existentes.isNotEmpty) {
        return CalendarioModel.fromMap(
            Map<String, dynamic>.from(existentes.first));
      }

      // 2) Si no hay, creamos uno nuevo como colaborativo
      final error = await crearCalendarioDeGrupo(
        idGrupo: idGrupo,
        nombre: nombre ?? 'Calendario de grupo #$idGrupo',
      );

      if (error != null) {
        debugPrint(
            '[CAL_SERV] Error al crear calendario de grupo: $error');
        return null;
      }

      // 3) Volvemos a listar y devolvemos el primero
      final nuevos = await listarCalendariosDeGrupo(idGrupo);
      if (nuevos.isEmpty) return null;

      return CalendarioModel.fromMap(
          Map<String, dynamic>.from(nuevos.first));
    } catch (e) {
      debugPrint(
          '[CAL_SERV] Error obtenerOCrearCalendarioDeGrupo: $e');
      return null;
    }
  }

  /// Eventos de todos los miembros de un grupo en un rango.
  static Future<List<Map<String, dynamic>>> listarEventosDeGrupoEnRango({
    required int idGrupo,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final miembros = await _cliente
        .from('perfil_grupo')
        .select('id_usuario')
        .eq('id_grupo', idGrupo);

    final idsMiembros =
    (miembros as List).map((m) => m['id_usuario'] as int).toList();

    if (idsMiembros.isEmpty) return [];

    final cals = await _cliente
        .from('calendario')
        .select('id, id_usuario')
        .inFilter('id_usuario', idsMiembros);

    final idsCalendarios =
    (cals as List).map((c) => c['id'] as int).toList();

    if (idsCalendarios.isEmpty) return [];

    final eventos = await _cliente
        .from('evento')
        .select('id, titulo, horario, id_calendario')
        .inFilter('id_calendario', idsCalendarios)
        .gte('horario', desde.toUtc().toIso8601String())
        .lte('horario', hasta.toUtc().toIso8601String());

    final mapaCalToUser = <int, int>{};
    for (final c in cals as List) {
      mapaCalToUser[c['id'] as int] = c['id_usuario'] as int;
    }

    return (eventos as List).map<Map<String, dynamic>>((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final idCal = map['id_calendario'] as int;
      map['id_usuario'] = mapaCalToUser[idCal];
      return map;
    }).toList();
  }

  /// Copia todos los eventos de una categoría desde el calendario personal.
  static Future<String?> copiarEventosDeCategoriaACalendarioDestino({
    required int idCalendarioDestino,
    required String categoria,
  }) async {
    try {
      final authUser = _cliente.auth.currentUser;
      if (authUser == null || authUser.email == null) {
        return 'No hay usuario autenticado';
      }

      final usuarioRow = await _cliente
          .from('usuario')
          .select('id, nombre, apellido, correo')
          .eq('correo', authUser.email!)
          .maybeSingle();

      if (usuarioRow == null) return 'Usuario no encontrado';

      final int idUsuario = usuarioRow['id'] as int;

      final calendariosPersonales =
      await listarCalendariosDeUsuario(idUsuario);
      if (calendariosPersonales.isEmpty) {
        return 'No tienes calendario personal creado';
      }

      final int idCalendarioPersonal =
      calendariosPersonales.first['id'] as int;

      final eventos = await _cliente
          .from('evento')
          .select('*')
          .eq('id_calendario', idCalendarioPersonal)
          .eq('tema', categoria);

      final lista = eventos as List;
      if (lista.isEmpty) {
        return 'No hay eventos con esa categoría en tu calendario personal';
      }

      final nuevos = <Map<String, dynamic>>[];

      for (final raw in lista) {
        final e = raw as Map<String, dynamic>;
        nuevos.add({
          'titulo': e['titulo'],
          'descripcion': e['descripcion'],
          'horario': e['horario'],
          'tema': e['tema'],
          'estado': e['estado'],
          'visibilidad': e['visibilidad'],
          'recordatorio_minutos': e['recordatorio_minutos'],
          'id_calendario': idCalendarioDestino,
          'creador': e['creador'],
        });
      }

      if (nuevos.isNotEmpty) {
        await _cliente.from('evento').insert(nuevos);
      }

      return null;
    } catch (e) {
      debugPrint('[CAL_SERV] Error copiarEventosDeCategoria: $e');
      return 'Error al copiar eventos: $e';
    }
  }

  /// Devuelve el calendario personal del usuario.
  /// Si no existe, lo crea. Ignora los calendarios que están ligados a grupos.
  static Future<CalendarioModel?> obtenerOCrearCalendarioPersonal(
      int idUsuario) async {
    try {
      // 1) Calendarios que "parecen" personales (id_usuario = usuario actual)
      final res = await _cliente
          .from('calendario')
          .select('id, id_usuario, nombre, zona_horaria, creado_en')
          .eq('id_usuario', idUsuario);

      final lista = List<Map<String, dynamic>>.from(res as List);

      if (lista.isNotEmpty) {
        // 2) Ver cuáles están ligados a grupos
        final ids = lista.map((c) => c['id'] as int).toList();

        final rel = await _cliente
            .from('grupo_calendario')
            .select('id_calendario')
            .inFilter('id_calendario', ids);

        final idsGrupo =
        (rel as List).map((r) => r['id_calendario'] as int).toSet();

        // 3) Preferimos uno que NO esté en grupo_calendario
        final soloPersonales =
        lista.where((c) => !idsGrupo.contains(c['id'] as int)).toList();

        final elegido =
        soloPersonales.isNotEmpty ? soloPersonales.first : lista.first;

        return CalendarioModel.fromMap(elegido);
      }

      // 4) Si no tiene ninguno, creamos uno nuevo como "personal"
      final insert = await _cliente
          .from('calendario')
          .insert({
        'id_usuario': idUsuario,
        'nombre': 'Calendario personal',
        'zona_horaria': 'America/La_Paz',
      })
          .select('id, id_usuario, nombre, zona_horaria, creado_en')
          .single();

      return CalendarioModel.fromMap(
          Map<String, dynamic>.from(insert as Map));
    } catch (e) {
      debugPrint(
          '[CAL_SERV] Error obtenerOCrearCalendarioPersonal: $e');
      return null;
    }
  }

}