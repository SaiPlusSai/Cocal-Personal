// lib/servicios/social/modelos_amigos.dart

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

  String get nombreCompleto => '$nombre $apellido'.trim();
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
