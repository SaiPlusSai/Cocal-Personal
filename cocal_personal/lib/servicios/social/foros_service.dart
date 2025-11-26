// lib/servicios/social/foros_service.dart
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';

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

  PostForo({
    required this.id,
    required this.idTema,
    required this.autor,
    required this.contenido,
    required this.creadoEn,
    required this.editadoEn,
    required this.estado,
  });

  factory PostForo.fromMap(Map<String, dynamic> map) {
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
    );
  }
}

class ForosService {
  static final _db = SupabaseService.cliente;

  // ===== helpers usuario actual =====

  static Future<Map<String, dynamic>> _getUsuarioActualRow() async {
    final user = _db.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay usuario autenticado');
    }

    final data = await _db
        .from('usuario')
        .select('id, nombre, apellido, correo')
        .eq('correo', user.email!)
        .maybeSingle();

    if (data == null) {
      throw Exception('No se encontró usuario en tabla usuario');
    }
    return data;
  }

  // ===== FORO por grupo =====

  /// Devuelve el foro principal del grupo; si no existe, lo crea.
  static Future<ForoResumen> obtenerOCrearForoDeGrupo(int idGrupo) async {
    try {
      // ¿Ya existe un foro para este grupo?
      final existing = await _db
          .from('foro')
          .select('id, id_grupo, titulo, autor, creado_en')
          .eq('id_grupo', idGrupo)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        return ForoResumen.fromMap(existing as Map<String, dynamic>);
      }

      // Crear foro "General"
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

      return ForoResumen.fromMap(inserted as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[ForosService] Error obtenerOCrearForoDeGrupo: $e');
      rethrow;
    }
  }

  // ===== TEMAS =====

  static Future<List<TemaForoResumen>> obtenerTemas(int idForo) async {
    try {
      final res = await _db
          .from('temas_foro')
          .select('id, id_foro, titulo, autor, creado_en')
          .eq('id_foro', idForo)
          .order('creado_en', ascending: false);

      return (res as List)
          .map((e) => TemaForoResumen.fromMap(e as Map<String, dynamic>))
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

  // ===== POSTS =====

  static Future<List<PostForo>> obtenerPosts(int idTema) async {
    try {
      final res = await _db
          .from('post_del_foro')
          .select('id, id_tema, autor, contenido, creado_en, editado_en, estado')
          .eq('id_tema', idTema)
          .order('creado_en', ascending: true);

      return (res as List)
          .map((e) => PostForo.fromMap(e as Map<String, dynamic>))
          .toList();
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
}
