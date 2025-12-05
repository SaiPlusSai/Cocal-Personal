// lib/servicios/temas_interes_service.dart
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

enum TemaInteres {
  MUSICA,
  PELICULA,
  VIDEOJUEGOS,
  ANIME,
  LITERATURA,
  DEPORTES,
}

extension TemaInteresExtension on TemaInteres {
  String get nombre {
    switch (this) {
      case TemaInteres.MUSICA:
        return 'Música';
      case TemaInteres.PELICULA:
        return 'Película';
      case TemaInteres.VIDEOJUEGOS:
        return 'Videojuegos';
      case TemaInteres.ANIME:
        return 'Anime';
      case TemaInteres.LITERATURA:
        return 'Literatura';
      case TemaInteres.DEPORTES:
        return 'Deportes';
    }
  }

  String get valor => name;
}

class TemasInteresService {
  static final _db = SupabaseService.cliente;

  /// Obtener temas de interés del usuario actual
  static Future<List<TemaInteres>> obtenerTemasActual() async {
    try {
      final authUser = _db.auth.currentUser;
      if (authUser == null || authUser.email == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener ID del usuario actual
      final usuarioRow = await _db
          .from('usuario')
          .select('id')
          .eq('correo', authUser.email!)
          .maybeSingle();

      if (usuarioRow == null) {
        throw Exception('Usuario no encontrado');
      }

      final userId = usuarioRow['id'] as int;
      return obtenerTemasDeUsuario(userId);
    } catch (e) {
      debugPrint('[TEMAS] Error obtenerTemasActual: $e');
      return [];
    }
  }

  /// Obtener temas de interés de cualquier usuario por ID
  static Future<List<TemaInteres>> obtenerTemasDeUsuario(int userId) async {
    try {
      final rows = await _db
          .from('temas_preferenciales')
          .select('tema')
          .eq('id_usuario', userId);

      return (rows as List)
          .map((e) {
            final tema = e['tema'] as String?;
            if (tema == null) return null;
            try {
              return TemaInteres.values.firstWhere((t) => t.name == tema);
            } catch (e) {
              debugPrint('[TEMAS] Tema desconocido: $tema');
              return null;
            }
          })
          .whereType<TemaInteres>()
          .toList();
    } catch (e) {
      debugPrint('[TEMAS] Error obtenerTemasDeUsuario: $e');
      return [];
    }
  }

  /// Añadir un tema de interés al usuario actual
  static Future<String?> agregarTema(TemaInteres tema) async {
    try {
      final authUser = _db.auth.currentUser;
      if (authUser == null || authUser.email == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener ID del usuario actual
      final usuarioRow = await _db
          .from('usuario')
          .select('id')
          .eq('correo', authUser.email!)
          .maybeSingle();

      if (usuarioRow == null) {
        throw Exception('Usuario no encontrado');
      }

      final userId = usuarioRow['id'] as int;
      final temaValor = tema.name; // Usar .name directamente
      debugPrint('[TEMAS] Intentando agregar tema: $temaValor para userId: $userId');

      // Verificar si ya existe
        final existentes = await _db
          .from('temas_preferenciales')
          .select('id')
          .eq('id_usuario', userId)
          .eq('tema', temaValor)
          .maybeSingle();

      if (existentes != null) {
        debugPrint('[TEMAS] Tema ya existe');
        return 'Este tema ya está en tus intereses';
      }

      // Insertar nuevo tema
      final response = await _db.from('temas_preferenciales').insert({
        'id_usuario': userId,
        'tema': temaValor,
      }).select();

      debugPrint('[TEMAS] Tema insertado exitosamente: $response');
      return null;
    } catch (e) {
      debugPrint('[TEMAS] Error agregarTema: $e');
      debugPrint('[TEMAS] Stack trace: ${StackTrace.current}');
      return 'Error al agregar tema: $e';
    }
  }

  /// Eliminar un tema de interés del usuario actual
  static Future<String?> eliminarTema(TemaInteres tema) async {
    try {
      final authUser = _db.auth.currentUser;
      if (authUser == null || authUser.email == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener ID del usuario actual
      final usuarioRow = await _db
          .from('usuario')
          .select('id')
          .eq('correo', authUser.email!)
          .maybeSingle();

      if (usuarioRow == null) {
        throw Exception('Usuario no encontrado');
      }

      final userId = usuarioRow['id'] as int;
      final temaValor = tema.name; // Usar .name directamente
      debugPrint('[TEMAS] Intentando eliminar tema: $temaValor para userId: $userId');

        final response = await _db
          .from('temas_preferenciales')
          .delete()
          .eq('id_usuario', userId)
          .eq('tema', temaValor);

      debugPrint('[TEMAS] Tema eliminado exitosamente: $response');
      return null;
    } catch (e) {
      debugPrint('[TEMAS] Error eliminarTema: $e');
      debugPrint('[TEMAS] Stack trace: ${StackTrace.current}');
      return 'Error al eliminar tema: $e';
    }
  }

  /// Obtener todos los temas disponibles
  static List<TemaInteres> obtenerTodosLosTemas() {
    return TemaInteres.values;
  }
}
