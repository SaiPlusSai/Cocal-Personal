// lib/servicios/social/foros_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import 'modelos_foro.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';

class ForosService {
  static final _db = SupabaseService.cliente;

  // =========================
  //  USUARIO ACTUAL
  // =========================
  static Future<Map<String, dynamic>> _getUsuarioActualRow() async {
    final user = _db.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay usuario autenticado');
    }

    final row = await _db
        .from('usuario')
        .select('id, nombre, apellido, correo')
        .eq('correo', user.email!)
        .maybeSingle();

    if (row == null) {
      throw Exception('Usuario no encontrado en tabla usuario');
    }
    return row;
  }

  // =========================
  //  FOROS Y TEMAS
  // =========================

  static Future<ForoResumen> obtenerOCrearForoDeGrupo(int idGrupo) async {
    try {
      final existing = await _db
          .from('foro')
          .select('id, id_grupo, titulo, autor, creado_en')
          .eq('id_grupo', idGrupo)
          .limit(1)
          .maybeSingle();

      if (existing != null) return ForoResumen.fromMap(existing);

      final me = await _getUsuarioActualRow();
      final autor = '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

      final inserted = await _db
          .from('foro')
          .insert({'id_grupo': idGrupo, 'titulo': 'Foro general', 'autor': autor})
          .select()
          .single();

      return ForoResumen.fromMap(inserted);
    } catch (e) {
      debugPrint('[ForosService] Error obtenerOCrearForoDeGrupo: $e');
      rethrow;
    }
  }

  static Future<List<TemaForoResumen>> obtenerTemas(int idForo) async {
    try {
      final res = await _db
          .from('temas_foro')
          .select('id, id_foro, titulo, autor, creado_en')
          .eq('id_foro', idForo)
          .order('creado_en', ascending: false);

      return (res as List).map((e) => TemaForoResumen.fromMap(e)).toList();
    } catch (e) {
      debugPrint('[ForosService] Error obtenerTemas: $e');
      return [];
    }
  }

  static Future<String?> crearTema({
    required int idForo,
    required String titulo,
  }) async {
    try {
      final me = await _getUsuarioActualRow();
      final autor = '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

      await _db.from('temas_foro').insert({
        'id_foro': idForo,
        'titulo': titulo,
        'autor': autor,
      });
      return null;
    } catch (e) {
      debugPrint('[ForosService] Error crearTema: $e');
      return 'No se pudo crear el tema';
    }
  }

  // =========================
  //  POSTS: SNAPSHOT (versión antigua)
  // =========================

  /// Versión que pega una vez a BD (útil para pantallas no realtime)
  static Future<List<PostForo>> obtenerPostsSnapshot(int idTema) async {
    try {
      final posts = await _db
          .from('post_del_foro')
          .select(
          'id, id_tema, autor, contenido, creado_en, editado_en, estado, id_comentario_padre, tipo_contenido, media_url')
          .eq('id_tema', idTema)
          .order('creado_en', ascending: true);

      if ((posts as List).isEmpty) return [];

      final postIds = posts.map((p) => p['id'] as int).toList();

      final reacciones = await _db
          .from('reaccion')
          .select('id_post, tipo, autor')
          .inFilter('id_post', postIds);

      final me = await _getUsuarioActualRow();
      final miCorreo = me['correo'] as String;
      final miNombreCompleto =
      '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

      final Map<int, Map<String, int>> conteos = {};
      final Map<int, String?> miReaccion = {};

      for (final r in (reacciones as List)) {
        final idPost = r['id_post'] as int;
        final tipo = r['tipo'] as String;
        final autor = r['autor'] as String;

        conteos.putIfAbsent(idPost, () => {});
        conteos[idPost]![tipo] = (conteos[idPost]![tipo] ?? 0) + 1;

        if (autor == miCorreo) miReaccion[idPost] = tipo;
      }

      return posts.map<PostForo>((p) {
        final id = p['id'] as int;
        final autorPost = p['autor'] as String? ?? '';
        final esActual = autorPost == miNombreCompleto;

        return PostForo.fromMap(
          p,
          reacciones: conteos[id] ?? {},
          miReaccion: miReaccion[id],
          esActual: esActual,
        );
      }).toList();
    } catch (e) {
      debugPrint('[ForosService] Error obtenerPostsSnapshot: $e');
      return [];
    }
  }

  /// Alias para no romper código viejo que use obtenerPosts(...)
  static Future<List<PostForo>> obtenerPosts(int idTema) =>
      obtenerPostsSnapshot(idTema);

  // =========================
  //  POSTS: STREAM REALTIME (chat en vivo)
  // =========================

  static Stream<List<PostForo>> escucharPostsDeTema(int idTema) async* {
    debugPrint('[ForosService] escucharPostsDeTema -> suscribiendo a idTema=$idTema');

    final me = await _getUsuarioActualRow();
    final miNombreCompleto =
    '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

    yield* _db
        .from('post_del_foro')
        .stream(primaryKey: ['id'])
        .eq('id_tema', idTema)
        .map((rows) {
      debugPrint(
          '[ForosService] STREAM post_del_foro cambio para tema=$idTema, filas=${rows.length}');
      for (final r in rows) {
        debugPrint(
            '  row id=${r['id']} id_tema=${r['id_tema']} autor=${r['autor']} contenido=${r['contenido']} creado_en=${r['creado_en']}');
      }

      rows.sort((a, b) {
        final da = DateTime.parse(a['creado_en'].toString());
        final db = DateTime.parse(b['creado_en'].toString());
        return da.compareTo(db);
      });

      return rows.map<PostForo>((p) {
        final autorPost = p['autor'] as String? ?? '';
        final esActual = autorPost == miNombreCompleto;

        return PostForo.fromMap(
          p,
          reacciones: const {},
          miReaccion: null,
          esActual: esActual,
        );
      }).toList();
    });
  }

  // =========================
  //  CREAR POST + REACCIONES
  // =========================

  static Future<String?> crearPost({
    required int idTema,
    required String contenido,
    int? idComentarioPadre,
    String tipoContenido = 'TEXTO',
    String? mediaUrl,
  }) async {
    try {
      final me = await _getUsuarioActualRow();
      final autor = '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

      debugPrint(
          '[ForosService] crearPost -> idTema=$idTema, autor=$autor, contenido="$contenido", padre=$idComentarioPadre');

      final inserted = await _db.from('post_del_foro').insert({
        'id_tema': idTema,
        'autor': autor,
        'contenido': contenido,
        'estado': 'PUBLICADO',
        'id_comentario_padre': idComentarioPadre,
        'tipo_contenido': tipoContenido,
        'media_url': mediaUrl,
      }).select('id, creado_en, id_tema').single();

      debugPrint(
          '[ForosService] crearPost -> INSERT OK id=${inserted['id']} id_tema=${inserted['id_tema']} creado_en=${inserted['creado_en']}');

      // El stream se actualiza solo
      return null;
    } catch (e) {
      debugPrint('[ForosService] Error crearPost: $e');
      return 'No se pudo publicar el mensaje';
    }
  }

  static Future<String?> toggleReaccion({
    required int idPost,
    required String tipo,
  }) async {
    try {
      final me = await _getUsuarioActualRow();
      final correo = me['correo'] as String;

      final existente = await _db
          .from('reaccion')
          .select('id, tipo')
          .eq('id_post', idPost)
          .eq('autor', correo)
          .maybeSingle();

      if (existente != null) {
        if (existente['tipo'] == tipo) {
          await _db.from('reaccion').delete().eq('id', existente['id']);
        } else {
          await _db
              .from('reaccion')
              .update({'tipo': tipo}).eq('id', existente['id']);
        }
      } else {
        await _db
            .from('reaccion')
            .insert({'id_post': idPost, 'tipo': tipo, 'autor': correo});
      }
      return null;
    } catch (e) {
      debugPrint('[ForosService] Error toggleReaccion: $e');
      return 'No se pudo registrar la reacción';
    }
  }

  // =========================
  //  TEMAS: STREAM REALTIME
  // =========================

  static Stream<List<TemaForoResumen>> escucharTemasDeForo(int idForo) {
    return _db
        .from('temas_foro')
        .stream(primaryKey: ['id'])
        .eq('id_foro', idForo)
        .map((rows) {
      rows.sort((a, b) {
        final da = DateTime.parse(a['creado_en'].toString());
        final db = DateTime.parse(b['creado_en'].toString());
        return db.compareTo(da); // más nuevos primero
      });

      return rows
          .map<TemaForoResumen>(
            (r) => TemaForoResumen.fromMap(r as Map<String, dynamic>),
      )
          .toList();
    });
  }
  // =========================
  //  STORAGE: subir media al bucket
  // =========================
  static Future<String?> subirMediaForo({
    required int idTema,
    required File file,
    required String carpeta, // 'imagenes' | 'videos'
  }) async {
    try {
      // Leemos bytes
      final Uint8List bytes = await file.readAsBytes();

      // Detectar extensión
      final nombreOriginal = file.path.split('/').last;
      String extension;

      if (nombreOriginal.contains('.')) {
        extension = nombreOriginal.split('.').last.toLowerCase();
      } else {
        // fallback razonable
        extension = 'jpg';
      }

      // Content-Type según extensión
      String contentType;
      if (extension == 'mp4') {
        contentType = 'video/mp4';
      } else if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else {
        // Intentar detectar por mime
        final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
        contentType = mime;
      }

      // Nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'tema_${idTema}_$timestamp.$extension';

      // Path dentro del bucket:
      //   imagenes/tema_2/tema_2_123456789.jpg
      //   videos/tema_2/tema_2_123456789.mp4
      final path = '$carpeta/tema_$idTema/$fileName';

      final res = await SupabaseService.cliente.storage
          .from('foro_media')
          .uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType),
      );

      // Si algo viene raro
      if (res.isEmpty) {
        debugPrint('[ForosService] subirMediaForo: upload result vacío');
      }

      final url = SupabaseService.cliente.storage
          .from('foro_media')
          .getPublicUrl(path);

      debugPrint('[ForosService] subirMediaForo OK, url=$url');
      return url;
    } on StorageException catch (e) {
      debugPrint('[ForosService] Error subirMediaForo (storage): $e');
      return null;
    } catch (e) {
      debugPrint('[ForosService] Error subirMediaForo: $e');
      return null;
    }
  }


}
