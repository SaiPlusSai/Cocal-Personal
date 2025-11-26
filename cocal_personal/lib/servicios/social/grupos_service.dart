import 'package:flutter/foundation.dart';
import '../supabase_service.dart';

class GrupoResumen {
  final int id;
  final String nombre;
  final String? descripcion;
  final String visibilidad;
  final String rol; // rol del usuario en ese grupo (DUENO, ADMIN, MIEMBRO, etc.)

  GrupoResumen({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.visibilidad,
    required this.rol,
  });

  factory GrupoResumen.fromMap(Map<String, dynamic> map) {
    return GrupoResumen(
      id: map['id'] as int,
      nombre: map['nombre'] as String? ?? '',
      descripcion: map['descripcion'] as String?,
      visibilidad: map['visibilidad'] as String? ?? 'PUBLICO',
      rol: map['rol'] as String? ?? 'MIEMBRO',
    );
  }
}

class MiembroGrupo {
  final int idPerfilGrupo;   // PK de perfil_grupo
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final String rol;          // DUENO / ADMIN / MIEMBRO...
  final String estado;       // ACTIVO / SUSPENDIDO...
  final DateTime unidoEn;
  final bool esActual;       // si es el usuario logueado

  MiembroGrupo({
    required this.idPerfilGrupo,
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.rol,
    required this.estado,
    required this.unidoEn,
    required this.esActual,
  });

  factory MiembroGrupo.fromMap(
      Map<String, dynamic> map,
      int idUsuarioActual,
      ) {
    final usuario = map['usuario'] as Map<String, dynamic>?;

    return MiembroGrupo(
      idPerfilGrupo: map['id'] as int,
      idUsuario: map['id_usuario'] as int,
      nombre: usuario?['nombre'] as String? ?? '',
      apellido: usuario?['apellido'] as String? ?? '',
      correo: usuario?['correo'] as String? ?? '',
      rol: map['rol'] as String? ?? 'MIEMBRO',
      estado: map['estado'] as String? ?? 'ACTIVO',
      unidoEn: DateTime.parse(map['unido_en'].toString()),
      esActual: (map['id_usuario'] as int) == idUsuarioActual,
    );
  }

  String get nombreCompleto => '$nombre $apellido'.trim();
}

class GruposService {
  static final _db = SupabaseService.cliente;

  // ===== Helpers usuario actual =====

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

  // ===== Grupos =====

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

  /// ¿El usuario actual es ADMIN/DUENO en este grupo?
  static Future<bool> esAdminDeGrupo(int idGrupo) async {
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int;

      final rows = await _db
          .from('perfil_grupo')
          .select('id, rol')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', miId)
          .inFilter('rol', ['DUENO', 'ADMIN'])
          .limit(1);

      return (rows as List).isNotEmpty;
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

      // Si es DUENO podrías impedir que salga sin transferir propiedad
      final miembro = await _db
          .from('perfil_grupo')
          .select('id, rol')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      if (miembro == null) return 'No perteneces a este grupo';

      if (miembro['rol'] == 'DUENO') {
        return 'El dueño del grupo no puede salir directamente. Transfiere el rol o elimina el grupo.';
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
      // 1) Verificar si ya es miembro
      final existente = await _db
          .from('perfil_grupo')
          .select('id')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      if (existente != null) {
        return 'Este usuario ya pertenece al grupo';
      }

      // 2) Insertar como miembro
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

  /// Cambiar rol de un miembro
  static Future<String?> cambiarRolMiembro({
    required int idPerfilGrupo,
    required String nuevoRol, // 'ADMIN', 'MIEMBRO', etc.
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

  /// Suspender / reactivar miembro (cambiar estado)
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

  /// Eliminar miembro del grupo
  static Future<String?> eliminarMiembro({
    required int idPerfilGrupo,
  }) async {
    try {
      await _db.from('perfil_grupo').delete().eq('id', idPerfilGrupo);
      return null;
    } catch (e) {
      debugPrint('[GruposService] Error eliminarMiembro: $e');
      return 'No se pudo eliminar al miembro';
    }
  }
}
