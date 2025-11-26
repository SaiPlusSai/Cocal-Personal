// lib/servicios/social/amigos_service.dart
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';

class UsuarioResumen {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;

  UsuarioResumen({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
  });

  factory UsuarioResumen.fromMap(Map<String, dynamic> map) {
    return UsuarioResumen(
      id: map['id'] as int,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      correo: map['correo'] ?? '',
    );
  }
}

class SolicitudAmistad {
  final int id;              // id de la fila en "solicitudes"
  final int idRemitente;
  final String nombreRemitente;
  final String nombreDestinatario;
  final bool aceptada;
  final DateTime creadaEn;

  SolicitudAmistad({
    required this.id,
    required this.idRemitente,
    required this.nombreRemitente,
    required this.nombreDestinatario,
    required this.aceptada,
    required this.creadaEn,
  });

  factory SolicitudAmistad.fromMap(Map<String, dynamic> map) {
    return SolicitudAmistad(
      id: map['id'] as int,
      idRemitente: map['id_usuario'] ?? map['id_remitente'] ?? 0,
      nombreRemitente: map['nombre_remitente'] ?? '',
      nombreDestinatario: map['nombre_destinatario'] ?? '',
      aceptada: map['aceptada'] ?? false,
      creadaEn: DateTime.parse(map['creada_en']),
    );
  }
}

class AmigosService {
  static final _db = SupabaseService.cliente;

  /// Devuelve el usuario actual (fila de tabla "usuario")
  static Future<Map<String, dynamic>> _getUsuarioActualRow() async {
    final authUser = _db.auth.currentUser;
    if (authUser == null || authUser.email == null) {
      throw Exception('No hay usuario autenticado');
    }

    final correo = authUser.email!;
    final row = await _db
        .from('usuario')
        .select('id, nombre, apellido, correo')
        .eq('correo', correo)
        .maybeSingle();

    if (row == null) {
      throw Exception('No se encontró al usuario con correo $correo en tabla usuario');
    }
    return row;
  }

  /// Buscar otros usuarios para enviar solicitud
  static Future<List<UsuarioResumen>> buscarUsuarios(String query) async {
    final me = await _getUsuarioActualRow();
    final miCorreo = me['correo'] as String;

    final rows = await _db
        .from('usuario')
        .select('id, nombre, apellido, correo')
        .neq('correo', miCorreo)
        .or(
      'nombre.ilike.%$query%,apellido.ilike.%$query%,correo.ilike.%$query%',
    )
        .limit(30);

    return (rows as List)
        .map((e) => UsuarioResumen.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Enviar solicitud de amistad a otro usuario
  static Future<String?> enviarSolicitud({
    required int idDestinatario,
  }) async {
    try {
      final me = await _getUsuarioActualRow();
      final miId = me['id'] as int;
      final miNombre = '${me['nombre']} ${me['apellido'] ?? ''}'.trim();

      // Evitar duplicados básicos: ¿ya hay solicitud?
      final existentes = await _db
          .from('solicitudes')
          .select('id, aceptada')
          .or(
        'and(id_usuario.eq.$idDestinatario,id_remitente.eq.$miId),'
            'and(id_usuario.eq.$miId,id_remitente.eq.$idDestinatario)',
      );

      if ((existentes as List).isNotEmpty) {
        return 'Ya existe una solicitud entre ustedes';
      }

      // Obtener datos del destinatario
      final dest = await _db
          .from('usuario')
          .select('nombre, apellido')
          .eq('id', idDestinatario)
          .maybeSingle();

      if (dest == null) {
        return 'Usuario destino no encontrado';
      }

      final nombreDest = '${dest['nombre']} ${dest['apellido'] ?? ''}'.trim();

      await _db.from('solicitudes').insert({
        'id_usuario': idDestinatario,
        'id_remitente': miId,
        'nombre_remitente': miNombre,
        'nombre_destinatario': nombreDest,
        'aceptada': false,
      });

      // (Opcional) actualizar bandeja_entrada.cantidad_solicitudes del destinatario

      return null;
    } catch (e) {
      debugPrint('[AMIGOS] Error enviarSolicitud: $e');
      return 'No se pudo enviar la solicitud';
    }
  }

  /// Solicitudes recibidas (pendientes) para el usuario actual
  static Future<List<SolicitudAmistad>> obtenerSolicitudesRecibidas() async {
    final me = await _getUsuarioActualRow();
    final miId = me['id'] as int;

    final rows = await _db
        .from('solicitudes')
        .select('id, id_remitente, nombre_remitente, nombre_destinatario, aceptada, creada_en, id_usuario')
        .eq('id_usuario', miId)
        .eq('aceptada', false)
        .order('creada_en', ascending: false);

    return (rows as List)
        .map((e) => SolicitudAmistad.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Aceptar o rechazar una solicitud
  static Future<String?> responderSolicitud({
    required int idSolicitud,
    required bool aceptar,
  }) async {
    try {
      if (aceptar) {
        await _db
            .from('solicitudes')
            .update({'aceptada': true})
            .eq('id', idSolicitud);
      } else {
        await _db.from('solicitudes').delete().eq('id', idSolicitud);
      }

      // (Opcional) disminuir contador en bandeja_entrada

      return null;
    } catch (e) {
      debugPrint('[AMIGOS] Error responderSolicitud: $e');
      return 'No se pudo actualizar la solicitud';
    }
  }

  /// Saber si dos usuarios son amigos (para el chip "Son amigos")
  static Future<bool> sonAmigos(int otroUsuarioId) async {
    final me = await _getUsuarioActualRow();
    final miId = me['id'] as int;

    final rows = await _db
        .from('solicitudes')
        .select('id')
        .or(
      'and(id_usuario.eq.$miId,id_remitente.eq.$otroUsuarioId,aceptada.eq.true),'
          'and(id_usuario.eq.$otroUsuarioId,id_remitente.eq.$miId,aceptada.eq.true)',
    )
        .limit(1);

    return (rows as List).isNotEmpty;
  }
  /// Lista de amigos (usuarios con solicitud aceptada con el usuario actual)
  static Future<List<UsuarioResumen>> obtenerAmigos() async {
    final me = await _getUsuarioActualRow();
    final miId = me['id'] as int;

    // 1) Buscar solicitudes aceptadas donde estoy como destinatario o remitente
    final rows = await _db
        .from('solicitudes')
        .select('id_usuario, id_remitente, aceptada')
        .eq('aceptada', true)
        .or('id_usuario.eq.$miId,id_remitente.eq.$miId');

    final lista = rows as List;

    // 2) Sacar los IDs de los otros usuarios (los amigos)
    final Set<int> idsAmigos = {};

    for (final raw in lista) {
      final map = raw as Map<String, dynamic>;
      final idUsuario = map['id_usuario'] as int?;
      final idRemitente = map['id_remitente'] as int?;

      if (idUsuario == null || idRemitente == null) continue;

      if (idUsuario == miId) {
        idsAmigos.add(idRemitente);
      } else if (idRemitente == miId) {
        idsAmigos.add(idUsuario);
      }
    }

    if (idsAmigos.isEmpty) {
      return [];
    }

    // 3) Traer datos de esos usuarios de la tabla "usuario"
    final usuariosRows = await _db
        .from('usuario')
        .select('id, nombre, apellido, correo')
        .inFilter('id', idsAmigos.toList());

    return (usuariosRows as List)
        .map((e) => UsuarioResumen.fromMap(e as Map<String, dynamic>))
        .toList();
  }

}
