// lib/servicios/social/modelos_foro.dart

class ForoResumen {
  final int id;
  final int idGrupo;
  final String titulo;
  final String autor;
  final DateTime creadoEn;

  ForoResumen({
    required this.id,
    required this.idGrupo,
    required this.titulo,
    required this.autor,
    required this.creadoEn,
  });

  factory ForoResumen.fromMap(Map<String, dynamic> map) {
    return ForoResumen(
      id: map['id'] as int,
      idGrupo: map['id_grupo'] as int,
      titulo: map['titulo'] as String? ?? '',
      autor: map['autor'] as String? ?? '',
      creadoEn: DateTime.parse(map['creado_en'].toString()),
    );
  }
}

class TemaForoResumen {
  final int id;
  final int idForo;
  final String titulo;
  final String autor;
  final DateTime creadoEn;

  TemaForoResumen({
    required this.id,
    required this.idForo,
    required this.titulo,
    required this.autor,
    required this.creadoEn,
  });

  factory TemaForoResumen.fromMap(Map<String, dynamic> map) {
    return TemaForoResumen(
      id: map['id'] as int,
      idForo: map['id_foro'] as int,
      titulo: map['titulo'] as String? ?? '',
      autor: map['autor'] as String? ?? '',
      creadoEn: DateTime.parse(map['creado_en'].toString()),
    );
  }
}

class PostForo {
  final int id;
  final int idTema;
  final String autor;
  final String contenido;
  final DateTime creadoEn;
  final DateTime? editadoEn;
  final String estado;

  /// Reacciones agregadas (tipo -> cantidad)
  final Map<String, int> reacciones;

  /// Reacción del usuario actual (o null)
  final String? miReaccion;

  /// Si el post pertenece al usuario actual (para alinearlo tipo chat)
  final bool esActual;

  /// id del comentario padre si es una respuesta
  final int? idComentarioPadre;

  PostForo({
    required this.id,
    required this.idTema,
    required this.autor,
    required this.contenido,
    required this.creadoEn,
    required this.editadoEn,
    required this.estado,
    required this.reacciones,
    required this.miReaccion,
    required this.esActual,
    this.idComentarioPadre,
  });

  factory PostForo.fromMap(
    Map<String, dynamic> map, {
    Map<String, int>? reacciones,
    String? miReaccion,
    bool esActual = false,
  }) {
    return PostForo(
      id: map['id'] as int,
      idTema: map['id_tema'] as int,
      autor: map['autor'] as String? ?? '',
      contenido: map['contenido'] as String? ?? '',
      creadoEn: DateTime.parse(map['creado_en'].toString()),
      editadoEn: map['editado_en'] != null
          ? DateTime.parse(map['editado_en'].toString())
          : null,
      estado: map['estado'] as String? ?? 'PUBLICADO',
      reacciones: reacciones ?? <String, int>{},
      miReaccion: miReaccion,
      esActual: esActual,
      idComentarioPadre: map['id_comentario_padre'] as int?,
    );
  }
}
