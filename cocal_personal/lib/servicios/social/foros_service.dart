// lib/servicios/social/foros_service.dart
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import 'modelos_foro.dart';

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
  //  FORO
  // =========================

  static Future<ForoResumen> obtenerOCrearForoDeGrupo(int idGrupo) async {
    try {
      final existing = await _db
          .from('foro')
          .select('id, id_grupo, titulo, autor, creado_en')
          .eq('id_grupo', idGrupo)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        return ForoResumen.fromMap(existing);
      }

      final me = await _getUsuarioActualRow();
      final autor = '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

      final inserted = await _db
          .from('foro')
          .insert({
        'id_grupo': idGrupo,
        'titulo': 'Foro general',
        'autor': autor,
      })
          .select()
          .single();

      return ForoResumen.fromMap(inserted);
    } catch (e) {
      debugPrint('[ForosService] Error obtenerOCrearForoDeGrupo: $e');
      rethrow;
    }
  }

  // =========================
  //  TEMAS
  // =========================

  static Future<List<TemaForoResumen>> obtenerTemas(int idForo) async {
    try {
      final res = await _db
          .from('temas_foro')
          .select('id, id_foro, titulo, autor, creado_en')
          .eq('id_foro', idForo)
          .order('creado_en', ascending: false);

      return (res as List)
          .map((e) => TemaForoResumen.fromMap(e))
          .toList();
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
  //  POSTS + REACCIONES
  // =========================

  static Future<List<PostForo>> obtenerPosts(int idTema) async {
    try {
      final posts = await _db
          .from('post_del_foro')
          .select(
        'id, id_tema, autor, contenido, creado_en, editado_en, estado',
      )
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

        if (autor == miCorreo) {
          miReaccion[idPost] = tipo;
        }
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
      debugPrint('[ForosService] Error obtenerPosts: $e');
      return [];
    }
  }

  static Future<String?> crearPost({
    required int idTema,
    required String contenido,
  }) async {
    try {
      final me = await _getUsuarioActualRow();
      final autor = '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

      await _db.from('post_del_foro').insert({
        'id_tema': idTema,
        'autor': autor,
        'contenido': contenido,
        'estado': 'PUBLICADO',
      });
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
              .update({'tipo': tipo})
              .eq('id', existente['id']);
        }
      } else {
        await _db.from('reaccion').insert({
          'id_post': idPost,
          'tipo': tipo,
          'autor': correo,
        });
      }
      return null;
    } catch (e) {
      debugPrint('[ForosService] Error toggleReaccion: $e');
      return 'No se pudo registrar la reacción';
    }
  }
}
