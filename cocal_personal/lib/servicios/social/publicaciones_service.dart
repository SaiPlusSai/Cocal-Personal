// lib/servicios/social/publicaciones_service.dart
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_service.dart';
import 'modelos_publicacion.dart';
import 'amigos_service.dart'; // para obtener amigos

class PublicacionesService {
  static final _db = SupabaseService.cliente;

  // Campos base que usamos en casi todos los selects
  static const String _camposPublicacionBase =
      'id, id_usuario, id_evento, contenido, visibilidad, '
      'creado_en, estado, '
      'usuario (id, nombre, apellido, foto_url), '
      'publicacion_media (id, url_imagen, orden, tipo)';

  // ===========================
  // Helpers
  // ===========================

  static Future<Map<String, dynamic>> _getUsuarioActualRow() async {
    final authUser = _db.auth.currentUser;
    if (authUser == null || authUser.email == null) {
      throw Exception('No hay usuario autenticado');
    }

    final correo = authUser.email!;
    final row = await _db
        .from('usuario')
        .select('id, nombre, apellido, correo, foto_url')
        .eq('correo', correo)
        .maybeSingle();

    if (row == null) {
      throw Exception('No se encontró al usuario con correo $correo');
    }
    return row;
  }
  /// Devuelve el id del usuario autenticado o null si falla
  static Future<int?> obtenerIdUsuarioActual() async {
    try {
      final row = await _getUsuarioActualRow();
      return row['id'] as int;
    } catch (e) {
      debugPrint('[PUB] Error obtenerIdUsuarioActual: $e');
      return null;
    }
  }


  // ===========================
  // Crear publicación
  // ===========================

  /// Crea una publicación con texto opcional, evento opcional y
  /// lista de archivos (XFile) que pueden ser imágenes o videos.
  ///
  /// [visibilidad] debe ser uno de:
  /// 'PUBLICO', 'AMIGOS', 'PRIVADO'
  static Future<PublicacionModel?> crearPublicacion({
    String? contenido,
    int? idEvento,
    String visibilidad = 'PUBLICO',
    List<XFile>? archivosMedia, // imágenes y/o videos
  }) async {
    try {
      final userRow = await _getUsuarioActualRow();
      final authUser = _db.auth.currentUser!;
      final idUsuario = userRow['id'] as int;

      // 1) Insertar fila en publicacion
      final inserted = await _db
          .from('publicacion')
          .insert({
        'id_usuario': idUsuario,
        'id_evento': idEvento,
        'contenido': contenido,
        'visibilidad': visibilidad,
        'estado': 'ACTIVO',
      })
          .select(
        'id, id_usuario, id_evento, contenido, visibilidad, creado_en, estado',
      )
          .single();

      final int idPublicacion = inserted['id'] as int;

      // 2) Subir media (si hay) al bucket "publicaciones"
      final List<MediaPublicacion> media = [];
      if (archivosMedia != null && archivosMedia.isNotEmpty) {
        for (int i = 0; i < archivosMedia.length; i++) {
          final file = archivosMedia[i];
          final bytes = await file.readAsBytes();
          final pathLocal = file.path;

          // Extensión
          String extension = 'jpg';
          final partes = pathLocal.split('.');
          if (partes.length > 1) {
            extension = partes.last.toLowerCase();
          }

          // Mime type
          String mime = lookupMimeType(pathLocal) ??
              (extension == 'mp4'
                  ? 'video/mp4'
                  : extension == 'png'
                  ? 'image/png'
                  : 'image/jpeg');

          final bool esVideo = mime.startsWith('video/');
          final String tipoMedia = esVideo ? 'VIDEO' : 'IMAGEN';

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final carpeta = esVideo ? 'videos' : 'imagenes';

          final storagePath =
              '${authUser.id}/posts/$idPublicacion/${carpeta}_${timestamp}_$i.$extension';

          await _db.storage.from('publicaciones').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mime,
            ),
          );

          final url =
          _db.storage.from('publicaciones').getPublicUrl(storagePath);

          final mediaRow = await _db
              .from('publicacion_media')
              .insert({
            'id_publicacion': idPublicacion,
            'url_imagen': url,
            'orden': i,
            'tipo': tipoMedia, // 'IMAGEN' o 'VIDEO'
          })
              .select('id, url_imagen, orden, tipo')
              .single();

          media.add(
            MediaPublicacion.fromMap(
              Map<String, dynamic>.from(mediaRow as Map),
            ),
          );
        }
      }

      // 3) Construir modelo completo (sin hacer otro select grande)
      return PublicacionModel(
        id: idPublicacion,
        idUsuario: idUsuario,
        idEvento: idEvento,
        contenido: contenido,
        visibilidad: visibilidad,
        creadoEn: DateTime.parse(inserted['creado_en'] as String),
        estado: inserted['estado']?.toString() ?? 'ACTIVO',
        nombreAutor: userRow['nombre'] as String?,
        apellidoAutor: userRow['apellido'] as String?,
        fotoAutor: userRow['foto_url'] as String?,
        media: media,
      );
    } catch (e) {
      debugPrint('[PUB] Error crearPublicacion: $e');
      return null;
    }
  }

  // ===========================
  // Publicaciones del perfil
  // ===========================

  /// Lista publicaciones visibles en el PERFIL de [idUsuarioPerfil]
  /// para el usuario actualmente logueado.
  ///
  /// - Si el perfil es mío → veo todas mis publicaciones.
  /// - Si es amigo → PUBLICO y AMIGOS.
  /// - Si no es amigo → solo PUBLICO.
  static Future<List<PublicacionModel>> obtenerPublicacionesDePerfil(
      int idUsuarioPerfil) async {
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int;

      final bool soyMismo = miId == idUsuarioPerfil;
      bool soyAmigo = false;

      if (!soyMismo) {
        soyAmigo = await AmigosService.sonAmigos(idUsuarioPerfil);
      }

      dynamic res;

      if (soyMismo) {
        // Todas mis publicaciones
        res = await _db
            .from('publicacion')
            .select(_camposPublicacionBase)
            .eq('id_usuario', idUsuarioPerfil)
            .order('creado_en', ascending: false);
      } else if (soyAmigo) {
        // Amigo → PUBLICO + AMIGOS
        res = await _db
            .from('publicacion')
            .select(_camposPublicacionBase)
            .eq('id_usuario', idUsuarioPerfil)
            .inFilter('visibilidad', ['PUBLICO', 'AMIGOS'])
            .order('creado_en', ascending: false);
      } else {
        // No amigo → solo PUBLICO
        res = await _db
            .from('publicacion')
            .select(_camposPublicacionBase)
            .eq('id_usuario', idUsuarioPerfil)
            .eq('visibilidad', 'PUBLICO')
            .order('creado_en', ascending: false);
      }

      final lista = res as List;

      return lista
          .map(
            (e) => PublicacionModel.fromMap(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();
    } catch (e) {
      debugPrint('[PUB] Error obtenerPublicacionesDePerfil: $e');
      return [];
    }
  }

  // ===========================
  // Publicaciones de un evento
  // ===========================

  static Future<List<PublicacionModel>> obtenerPublicacionesDeEvento(
      int idEvento) async {
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int;

      // IDs de amigos
      final amigos = await AmigosService.obtenerAmigos();
      final idsAmigos = amigos.map((a) => a.id).toList();

      // 1) Mis publicaciones sobre este evento (cualquier visibilidad)
      final miasRes = await _db
          .from('publicacion')
          .select(_camposPublicacionBase)
          .eq('id_evento', idEvento)
          .eq('id_usuario', miId)
          .order('creado_en', ascending: false);

      final mias = (miasRes as List)
          .map((e) => PublicacionModel.fromMap(
        Map<String, dynamic>.from(e as Map),
      ))
          .toList();

      // 2) Publicaciones de amigos (PUBLICO y AMIGOS)
      List<PublicacionModel> deAmigos = [];
      if (idsAmigos.isNotEmpty) {
        final amigosRes = await _db
            .from('publicacion')
            .select(_camposPublicacionBase)
            .eq('id_evento', idEvento)
            .inFilter('id_usuario', idsAmigos)
            .inFilter('visibilidad', ['PUBLICO', 'AMIGOS'])
            .order('creado_en', ascending: false);

        deAmigos = (amigosRes as List)
            .map((e) => PublicacionModel.fromMap(
          Map<String, dynamic>.from(e as Map),
        ))
            .toList();
      }

      // 3) Combinar y ordenar
      final todas = [...mias, ...deAmigos];
      todas.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return todas;
    } catch (e) {
      debugPrint('[PUB] Error obtenerPublicacionesDeEvento: $e');
      return [];
    }
  }
  static Future<String?> eliminarPublicacion(int idPublicacion) async {
    try {
      final me = await _getUsuarioActualRow();
      final idUsuario = me['id'] as int;

      await _db
          .from('publicacion')
          .delete()
          .match({'id': idPublicacion, 'id_usuario': idUsuario});

      // Asumimos que en la BD tenés ON DELETE CASCADE para media/comentarios
      return null;
    } catch (e) {
      debugPrint('[PUB] Error eliminarPublicacion: $e');
      return 'No se pudo eliminar la publicación';
    }
  }


  // ===========================
  // Feed (yo + amigos)
  // ===========================

  /// Feed principal (publicaciones mías + amigos)
  static Future<List<PublicacionModel>> obtenerFeed() async {
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int;

      // 1) Mis publicaciones (cualquier visibilidad)
      final miasRes = await _db
          .from('publicacion')
          .select(_camposPublicacionBase)
          .eq('id_usuario', miId)
          .order('creado_en', ascending: false);

      final mias = (miasRes as List)
          .map(
            (e) => PublicacionModel.fromMap(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();

      // 2) Publicaciones de amigos (PUBLICO y AMIGOS)
      final amigos = await AmigosService.obtenerAmigos();
      final idsAmigos = amigos.map((a) => a.id).toList();

      if (idsAmigos.isEmpty) {
        // solo mis publicaciones
        return mias;
      }

      final amigosRes = await _db
          .from('publicacion')
          .select(_camposPublicacionBase)
          .inFilter('id_usuario', idsAmigos)
          .inFilter('visibilidad', ['PUBLICO', 'AMIGOS'])
          .order('creado_en', ascending: false);

      final deAmigos = (amigosRes as List)
          .map(
            (e) => PublicacionModel.fromMap(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();

      final todas = [...mias, ...deAmigos];
      todas.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return todas;
    } catch (e) {
      debugPrint('[PUB] Error obtenerFeed: $e');
      return [];
    }
  }

  // ===========================
  // Feed (solo amigos)
  // ===========================

  /// Publicaciones SOLO de amigos (PUBLICO y AMIGOS)
  static Future<List<PublicacionModel>> obtenerFeedSoloAmigos() async {
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int; // por si luego quieres excluirte

      final amigos = await AmigosService.obtenerAmigos();
      final idsAmigos = amigos.map((a) => a.id).toList();

      if (idsAmigos.isEmpty) {
        return [];
      }

      final amigosRes = await _db
          .from('publicacion')
          .select(_camposPublicacionBase)
          .inFilter('id_usuario', idsAmigos)
          .inFilter('visibilidad', ['PUBLICO', 'AMIGOS'])
          .order('creado_en', ascending: false);

      final deAmigos = (amigosRes as List)
          .map(
            (e) => PublicacionModel.fromMap(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();

      // Por si quieres asegurarte que no se cuele nada tuyo:
      deAmigos.removeWhere((p) => p.idUsuario == miId);

      return deAmigos;
    } catch (e) {
      debugPrint('[PUB] Error obtenerFeedSoloAmigos: $e');
      return [];
    }
  }

  /// ✅ Alias para el feed que usa la pantalla de inicio
  /// (solo publicaciones de amigos que sigues)
  static Future<List<PublicacionModel>> obtenerFeedGeneral() {
    return obtenerFeedSoloAmigos();
  }

  // ===========================
  // Comentarios
  // ===========================
  static Future<int> contarComentarios(int idPublicacion) async {
    try {
      final res = await _db
          .from('comentario_publicacion')
          .select('id')
          .eq('id_publicacion', idPublicacion);

      final lista = res as List;
      return lista.length;
    } catch (e) {
      debugPrint('[PUB] Error contarComentarios: $e');
      return 0;
    }
  }
  static Future<String?> eliminarComentario(int idComentario) async {
    try {
      final me = await _getUsuarioActualRow();
      final idUsuario = me['id'] as int;

      await _db
          .from('comentario_publicacion')
          .delete()
          .match({'id': idComentario, 'id_usuario': idUsuario});

      return null;
    } catch (e) {
      debugPrint('[PUB] Error eliminarComentario: $e');
      return 'No se pudo eliminar el comentario';
    }
  }

  static Future<List<ComentarioPublicacionModel>> obtenerComentarios(
      int idPublicacion) async {
    try {
      final res = await _db
          .from('comentario_publicacion')
          .select(
        'id, id_publicacion, id_usuario, contenido, creado_en, '
            'usuario (id, nombre, apellido, foto_url)',
      )
          .eq('id_publicacion', idPublicacion)
          .order('creado_en', ascending: true);

      final lista = res as List;
      return lista
          .map(
            (e) => ComentarioPublicacionModel.fromMap(
          Map<String, dynamic>.from(e as Map),
        ),
      )
          .toList();
    } catch (e) {
      debugPrint('[PUB] Error obtenerComentarios: $e');
      return [];
    }
  }

  static Future<String?> crearComentario({
    required int idPublicacion,
    required String contenido,
  }) async {
    try {
      final me = await _getUsuarioActualRow();
      final idUsuario = me['id'] as int;

      await _db.from('comentario_publicacion').insert({
        'id_publicacion': idPublicacion,
        'id_usuario': idUsuario,
        'contenido': contenido,
      });

      return null;
    } catch (e) {
      debugPrint('[PUB] Error crearComentario: $e');
      return 'No se pudo guardar el comentario';
    }
  }

  // ===========================
  // Reacciones simples (LIKE)
  // ===========================

  static Future<String?> toggleLike(int idPublicacion) async {
    try {
      final me = await _getUsuarioActualRow();
      final idUsuario = me['id'] as int;

      // ¿Ya reaccionó?
      final existing = await _db
          .from('reaccion_publicacion')
          .select('id')
          .eq('id_publicacion', idPublicacion)
          .eq('id_usuario', idUsuario)
          .maybeSingle();

      if (existing != null) {
        // quitar like
        await _db
            .from('reaccion_publicacion')
            .delete()
            .eq('id', existing['id']);
      } else {
        // agregar like (tipo por defecto: LIKE)
        await _db.from('reaccion_publicacion').insert({
          'id_publicacion': idPublicacion,
          'id_usuario': idUsuario,
          'tipo': 'LIKE',
        });
      }

      return null;
    } catch (e) {
      debugPrint('[PUB] Error toggleLike: $e');
      return 'No se pudo actualizar la reacción';
    }
  }

  static Future<int> contarLikes(int idPublicacion) async {
    try {
      final res = await _db
          .from('reaccion_publicacion')
          .select('id')
          .eq('id_publicacion', idPublicacion);

      final lista = res as List;
      return lista.length; // más simple, sin usar CountOption
    } catch (e) {
      debugPrint('[PUB] Error contarLikes: $e');
      return 0;
    }
  }
}
