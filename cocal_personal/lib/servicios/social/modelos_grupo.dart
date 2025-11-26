// lib/servicios/social/modelos_grupo.dart

class GrupoResumen {
  final int id;
  final String nombre;
  final String? descripcion;
  final String visibilidad;
  final String rol; // DUENO / MOD / MIEMBRO...

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
  final String rol;          // DUENO / MOD / MIEMBRO...
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
