// lib/servicios/social/modelos_publicacion.dart
class MediaPublicacion {
  final int id;
  final String urlImagen;       // puede ser imagen o video
  final int? orden;
  final String tipo;            // 'IMAGEN' o 'VIDEO'

  bool get esVideo => tipo.toUpperCase() == 'VIDEO';
  bool get esImagen => !esVideo;

  MediaPublicacion({
    required this.id,
    required this.urlImagen,
    this.orden,
    this.tipo = 'IMAGEN',
  });

  factory MediaPublicacion.fromMap(Map<String, dynamic> map) {
    return MediaPublicacion(
      id: map['id'] as int,
      urlImagen: map['url_imagen'] as String,
      orden: map['orden'] as int?,
      tipo: (map['tipo'] as String?) ?? 'IMAGEN',
    );
  }
}

class PublicacionModel {
  final int id;
  final int idUsuario;
  final int? idEvento;
  final String? contenido;
  final String visibilidad;
  final DateTime creadoEn;
  final String estado;

  final String? nombreAutor;
  final String? apellidoAutor;
  final String? fotoAutor;

  final List<MediaPublicacion> media;

  PublicacionModel({
    required this.id,
    required this.idUsuario,
    this.idEvento,
    this.contenido,
    required this.visibilidad,
    required this.creadoEn,
    required this.estado,
    this.nombreAutor,
    this.apellidoAutor,
    this.fotoAutor,
    this.media = const [],
  });

  factory PublicacionModel.fromMap(Map<String, dynamic> map) {
    final usuario = map['usuario'] as Map?;
    final mediaList = map['publicacion_media'] as List? ?? [];

    return PublicacionModel(
      id: map['id'] as int,
      idUsuario: map['id_usuario'] as int,
      idEvento: map['id_evento'] as int?,
      contenido: map['contenido'] as String?,
      visibilidad: map['visibilidad'] as String? ?? 'PUBLICO',
      creadoEn: DateTime.parse(map['creado_en'] as String),
      estado: map['estado'] as String? ?? 'ACTIVO',
      nombreAutor: usuario != null ? usuario['nombre'] as String? : null,
      apellidoAutor: usuario != null ? usuario['apellido'] as String? : null,
      fotoAutor: usuario != null ? usuario['foto_url'] as String? : null,
      media: mediaList
          .map((e) => MediaPublicacion.fromMap(
        Map<String, dynamic>.from(e as Map),
      ))
          .toList(),
    );
  }
}

class ComentarioPublicacionModel {
  final int id;
  final int idPublicacion;
  final int idUsuario;
  final String contenido;
  final DateTime creadoEn;

  final String? nombreAutor;
  final String? apellidoAutor;
  final String? fotoAutor;

  ComentarioPublicacionModel({
    required this.id,
    required this.idPublicacion,
    required this.idUsuario,
    required this.contenido,
    required this.creadoEn,
    this.nombreAutor,
    this.apellidoAutor,
    this.fotoAutor,
  });

  factory ComentarioPublicacionModel.fromMap(Map<String, dynamic> map) {
    final usuario = map['usuario'] as Map?;

    return ComentarioPublicacionModel(
      id: map['id'] as int,
      idPublicacion: map['id_publicacion'] as int,
      idUsuario: map['id_usuario'] as int,
      contenido: map['contenido'] as String,
      creadoEn: DateTime.parse(map['creado_en'] as String),
      nombreAutor: usuario != null ? usuario['nombre'] as String? : null,
      apellidoAutor: usuario != null ? usuario['apellido'] as String? : null,
      fotoAutor: usuario != null ? usuario['foto_url'] as String? : null,
    );
  }
}
