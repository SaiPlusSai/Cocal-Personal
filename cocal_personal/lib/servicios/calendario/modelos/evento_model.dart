// lib/servicios/calendario/modelos/evento_model.dart

class EventoModel {
  final int id;
  final String titulo;
  final String? descripcion;
  final DateTime horario;
  final String visibilidad;            // enum en BD → string en app
  final String? creador;
  final int idCalendario;
  final String? tema;                  // enum en BD
  final String estado;                 // enum en BD
  final int? recordatorioMinutos;

  /// Campo “extra” para consultas donde traes también al usuario
  /// (ej: eventos de grupo con id_usuario)
  final int? idUsuario;

  EventoModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.horario,
    required this.visibilidad,
    this.creador,
    required this.idCalendario,
    this.tema,
    required this.estado,
    this.recordatorioMinutos,
    this.idUsuario,
  });

  factory EventoModel.fromMap(Map<String, dynamic> map) {
    return EventoModel(
      id: map['id'] as int,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'],
      horario: DateTime.parse(map['horario'] as String).toLocal(),
      visibilidad: map['visibilidad']?.toString() ?? 'PUBLICO',
      creador: map['creador'],
      idCalendario: map['id_calendario'] as int,
      tema: map['tema']?.toString(),
      estado: map['estado']?.toString() ?? 'ACTIVO',
      recordatorioMinutos: map['recordatorio_minutos'] as int?,
      idUsuario: map['id_usuario'] as int?, // solo viene en algunas queries
    );
  }

  /// Para inserts (sin id, sin idUsuario)
  Map<String, dynamic> toInsertMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'horario': horario.toUtc().toIso8601String(),
      'visibilidad': visibilidad,
      'creador': creador,
      'id_calendario': idCalendario,
      'tema': tema,
      'estado': estado,
      'recordatorio_minutos': recordatorioMinutos,
    };
  }

  EventoModel copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    DateTime? horario,
    String? visibilidad,
    String? creador,
    int? idCalendario,
    String? tema,
    String? estado,
    int? recordatorioMinutos,
    int? idUsuario,
  }) {
    return EventoModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      horario: horario ?? this.horario,
      visibilidad: visibilidad ?? this.visibilidad,
      creador: creador ?? this.creador,
      idCalendario: idCalendario ?? this.idCalendario,
      tema: tema ?? this.tema,
      estado: estado ?? this.estado,
      recordatorioMinutos: recordatorioMinutos ?? this.recordatorioMinutos,
      idUsuario: idUsuario ?? this.idUsuario,
    );
  }
}
