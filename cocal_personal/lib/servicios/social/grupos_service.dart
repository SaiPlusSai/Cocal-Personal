// lib/servicios/social/grupos_service.dart
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import 'modelos_grupo.dart';

class GruposService {
  static final _db = SupabaseService.cliente;

  // ==========================
  //   Helpers usuario actual
  // ==========================

  /// Devuelve la fila completa de tabla "usuario" para el auth.currentUser
  static Future<Map<String, dynamic>> _getUsuarioActualRow() async {
    final user = _db.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay usuario autenticado');
    }

    try {
      final data = await _db
          .from('usuario')
          .select('id, nombre, apellido, correo')
          .eq('correo', user.email!)
          .maybeSingle();

      if (data == null) {
        throw Exception(
          'No se encontró usuario con correo ${user.email} en tabla usuario',
        );
      }

      return data;
    } catch (e) {
      debugPrint('[GruposService] Error obteniendo usuario actual: $e');
      rethrow;
    }
  }

  /// Versión que solo devuelve el id (por comodidad)
  static Future<int?> _obtenerUsuarioActualId() async {
    try {
      final row = await _getUsuarioActualRow();
      return row['id'] as int;
    } catch (_) {
      return null;
    }
  }

  // ==========================
  //          GRUPOS
  // ==========================

  /// Crear grupo y asignar al usuario actual como DUENO
  static Future<String?> crearGrupo({
    required String nombre,
    String? descripcion,
    String visibilidad = 'PUBLICO', // debe coincidir con el enum
  }) async {
    try {
      final me = await _getUsuarioActualRow();
      final idUsuario = me['id'] as int;

      // 1) Insertar en grupo
      final inserted = await _db
          .from('grupo')
          .insert({
        'nombre': nombre,
        'descripcion': descripcion,
        'visibilidad': visibilidad,
        'creador': me['correo'] as String? ?? idUsuario.toString(),
      })
          .select()
          .single();

      final int idGrupo = inserted['id'] as int;

      // 2) Crear perfil_grupo como DUENO
      await _db.from('perfil_grupo').insert({
        'id_usuario': idUsuario,
        'id_grupo': idGrupo,
        'rol': 'DUENO',
        'estado': 'ACTIVO',
      });

      return null;
    } catch (e) {
      debugPrint('[GruposService] Error al crear grupo: $e');
      return 'No se pudo crear el grupo';
    }
  }

  /// Grupos donde participa el usuario actual (por perfil_grupo)
  static Future<List<GrupoResumen>> obtenerMisGrupos() async {
    final List<GrupoResumen> out = [];
    try {
      final idUsuario = await _obtenerUsuarioActualId();
      if (idUsuario == null) return out;

      final res = await _db
          .from('perfil_grupo')
          .select('rol, grupo ( id, nombre, descripcion, visibilidad )')
          .eq('id_usuario', idUsuario);

      for (final row in (res as List)) {
        final grupo = row['grupo'] as Map<String, dynamic>?;
        if (grupo == null) continue;
        final map = {
          'id': grupo['id'],
          'nombre': grupo['nombre'],
          'descripcion': grupo['descripcion'],
          'visibilidad': grupo['visibilidad'],
          'rol': row['rol'],
        };
        out.add(GrupoResumen.fromMap(map));
      }
    } catch (e) {
      debugPrint('[GruposService] Error al obtener mis grupos: $e');
    }
    return out;
  }

  /// ¿El usuario actual es DUENO o MOD en este grupo?
  static Future<bool> esAdminDeGrupo(int idGrupo) async {
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int;

      final row = await _db
          .from('perfil_grupo')
          .select('rol')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', miId)
          .maybeSingle();

      if (row == null) {
        debugPrint(
            '[GruposService] esAdminDeGrupo: no hay registro en perfil_grupo');
        return false;
      }

      final rol = row['rol'] as String? ?? '';
      debugPrint('[GruposService] esAdminDeGrupo: rol actual = $rol');
      return rol == 'DUENO' || rol == 'MOD';
    } catch (e) {
      debugPrint('[GruposService] Error esAdminDeGrupo: $e');
      return false;
    }
  }

  /// Miembros de un grupo (con info del usuario)
  static Future<List<MiembroGrupo>> obtenerMiembros(int idGrupo) async {
    final List<MiembroGrupo> out = [];
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int;

      final res = await _db
          .from('perfil_grupo')
          .select(
        'id, id_usuario, rol, estado, unido_en, usuario ( id, nombre, apellido, correo )',
      )
          .eq('id_grupo', idGrupo)
          .order('unido_en', ascending: true);

      for (final row in (res as List)) {
        final map = row as Map<String, dynamic>;
        out.add(MiembroGrupo.fromMap(map, miId));
      }
    } catch (e) {
      debugPrint('[GruposService] Error al obtener miembros del grupo: $e');
    }
    return out;
  }

  /// Salir de un grupo (elimina el perfil_grupo)
  static Future<String?> salirDeGrupo(int idGrupo) async {
    try {
      final me = await _getUsuarioActualRow();
      final idUsuario = me['id'] as int;

      final miembro = await _db
          .from('perfil_grupo')
          .select('id, rol')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      if (miembro == null) return 'No perteneces a este grupo';

      if (miembro['rol'] == 'DUENO') {
        return 'El dueño del grupo no puede salir directamente. '
            'Transfiere el rol o elimina el grupo.';
      }

      await _db
          .from('perfil_grupo')
          .delete()
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', idUsuario);

      return null;
    } catch (e) {
      debugPrint('[GruposService] Error al salir del grupo: $e');
      return 'No se pudo salir del grupo';
    }
  }

  /// Agregar un usuario (amigo) a un grupo como miembro
  static Future<String?> agregarMiembro({
    required int idGrupo,
    required int idUsuario,
    String rol = 'MIEMBRO',
  }) async {
    try {
      final existente = await _db
          .from('perfil_grupo')
          .select('id')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      if (existente != null) {
        return 'Este usuario ya pertenece al grupo';
      }

      await _db.from('perfil_grupo').insert({
        'id_usuario': idUsuario,
        'id_grupo': idGrupo,
        'rol': rol,
        'estado': 'ACTIVO',
      });

      return null;
    } catch (e) {
      debugPrint('[GruposService] Error al agregar miembro: $e');
      return 'No se pudo agregar al usuario al grupo';
    }
  }

  // ==========================
  //   ADMINISTRACIÓN MIEMBROS
  // ==========================

  /// Cambiar rol de un miembro (por PK de perfil_grupo)
  static Future<String?> cambiarRolMiembro({
    required int idPerfilGrupo,
    required String nuevoRol, // 'MOD', 'MIEMBRO', etc.
  }) async {
    try {
      await _db
          .from('perfil_grupo')
          .update({'rol': nuevoRol})
          .eq('id', idPerfilGrupo);

      return null;
    } catch (e) {
      debugPrint('[GruposService] Error cambiarRolMiembro: $e');
      return 'No se pudo cambiar el rol';
    }
  }

  /// Suspender / reactivar miembro (cambiar estado, por PK de perfil_grupo)
  static Future<String?> cambiarEstadoMiembro({
    required int idPerfilGrupo,
    required String nuevoEstado, // 'ACTIVO' / 'SUSPENDIDO'
  }) async {
    try {
      await _db
          .from('perfil_grupo')
          .update({'estado': nuevoEstado})
          .eq('id', idPerfilGrupo);

      return null;
    } catch (e) {
      debugPrint('[GruposService] Error cambiarEstadoMiembro: $e');
      return 'No se pudo cambiar el estado';
    }
  }

  /// Eliminar miembro del grupo (kick), por PK de perfil_grupo
  static Future<String?> eliminarMiembro({
    required int idPerfilGrupo,
  }) async {
    try {
      await _db.from('perfil_grupo').delete().eq('id', idPerfilGrupo);
      return null;
    } catch (e) {
      debugPrint('[GruposService] Error en eliminarMiembro: $e');
      return 'No se pudo eliminar al miembro';
    }
  }

  /// Obtener MI rol en un grupo (para saber qué permisos tengo)
  static Future<String?> obtenerMiRol(int idGrupo) async {
    try {
      final idUsuario = await _obtenerUsuarioActualId();
      if (idUsuario == null) return null;

      final res = await _db
          .from('perfil_grupo')
          .select('rol')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      return res?['rol'];
    } catch (e) {
      debugPrint('[GruposService] Error en obtenerMiRol: $e');
      return null;
    }
  }
}
