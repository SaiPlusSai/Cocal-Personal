// lib/servicios/calendario/modelos/calendario_model.dart
class CalendarioModel {
  final int id;
  final int? idUsuario;
  final String nombre;
  final String? zonaHoraria;
  final DateTime? creadoEn;

  CalendarioModel({
    required this.id,
    this.idUsuario,
    required this.nombre,
    this.zonaHoraria,
    this.creadoEn,
  });

  factory CalendarioModel.fromMap(Map<String, dynamic> map) {
    return CalendarioModel(
      id: map['id'] as int,
      idUsuario: map['id_usuario'] as int?,
      nombre: map['nombre'] ?? '',
      zonaHoraria: map['zona_horaria'] as String?,
      creadoEn: map['creado_en'] != null
          ? DateTime.parse(map['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'zona_horaria': zonaHoraria,
    };
  }
}
