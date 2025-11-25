//lib/servicios/social/grupos_service.dart
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';

class GrupoResumen {
  final int id;
  final String nombre;
  final String? descripcion;
  final String visibilidad;
  final String rol; // rol del usuario en ese grupo (DUENO, MIEMBRO, etc.)

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
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      visibilidad: map['visibilidad'] as String? ?? 'PUBLICO',
      rol: map['rol'] as String? ?? 'MIEMBRO',
    );
  }
}

class MiembroGrupo {
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String rol;
  final String estado;

  MiembroGrupo({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.estado,
  });

  factory MiembroGrupo.fromMap(Map<String, dynamic> map) {
    return MiembroGrupo(
      idUsuario: map['id_usuario'] as int,
      nombre: map['nombre'] as String? ?? '',
      apellido: map['apellido'] as String? ?? '',
      rol: map['rol'] as String? ?? 'MIEMBRO',
      estado: map['estado'] as String? ?? 'ACTIVO',
    );
  }

  String get nombreCompleto => '$nombre $apellido'.trim();
}

class GruposService {
  static final _db = SupabaseService.cliente;

  // 🔐 Helper: obtener id de la tabla usuario a partir del auth.currentUser
  static Future<int?> _obtenerUsuarioActualId() async {
    final user = _db.auth.currentUser;
    if (user == null || user.email == null) return null;

    try {
      final data = await _db
          .from('usuario')
          .select('id')
          .eq('correo', user.email!)
          .maybeSingle();

      if (data == null) return null;
      return data['id'] as int;
    } catch (e) {
      debugPrint('[GruposService] Error obteniendo usuario actual: $e');
      return null;
    }
  }

  /// Crear grupo y asignar al usuario actual como DUENO
  static Future<String?> crearGrupo({
    required String nombre,
    String? descripcion,
    String visibilidad = 'PUBLICO', // debe coincidir con el enum
  }) async {
    try {
      final idUsuario = await _obtenerUsuarioActualId();
      if (idUsuario == null) return 'No se pudo identificar al usuario actual';

      // 1) Insertar en grupo
      final inserted = await _db
          .from('grupo')
          .insert({
        'nombre': nombre,
        'descripcion': descripcion,
        'visibilidad': visibilidad,
        'creador': idUsuario.toString(), // o correo si prefieres
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

  /// Miembros de un grupo
  static Future<List<MiembroGrupo>> obtenerMiembros(int idGrupo) async {
    final List<MiembroGrupo> out = [];
    try {
      final res = await _db
          .from('perfil_grupo')
          .select('id_usuario, rol, estado, usuario ( nombre, apellido )')
          .eq('id_grupo', idGrupo);

      for (final row in (res as List)) {
        final u = row['usuario'] as Map<String, dynamic>?;

        final map = {
          'id_usuario': row['id_usuario'],
          'rol': row['rol'],
          'estado': row['estado'],
          'nombre': u?['nombre'],
          'apellido': u?['apellido'],
        };
        out.add(MiembroGrupo.fromMap(map));
      }
    } catch (e) {
      debugPrint('[GruposService] Error al obtener miembros del grupo: $e');
    }
    return out;
  }

  /// Salir de un grupo (elimina el perfil_grupo)
  static Future<String?> salirDeGrupo(int idGrupo) async {
    try {
      final idUsuario = await _obtenerUsuarioActualId();
      if (idUsuario == null) return 'No se pudo identificar al usuario actual';

      // Si es DUENO podrías impedir que salga sin transferir propiedad
      final miembros = await _db
          .from('perfil_grupo')
          .select('id, rol')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      if (miembros == null) return 'No perteneces a este grupo';

      if (miembros['rol'] == 'DUENO') {
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
}
