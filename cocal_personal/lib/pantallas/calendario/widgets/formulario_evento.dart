//lib/pantallas/calendario/widgets/formulario_evento.dart
import 'package:flutter/material.dart';

class FormularioEvento extends StatelessWidget {
  final TextEditingController tituloCtl;
  final TextEditingController descCtl;
  final DateTime fecha;
  final TimeOfDay hora;

  final String tema;
  final String estado;
  final String visibilidad;

  final int? recordatorioMinutos;

  final List<String> temas;
  final List<String> estados;
  final List<String> visibilidades;

  final ValueChanged<String> onTemaChanged;
  final ValueChanged<String> onEstadoChanged;
  final ValueChanged<String> onVisibilidadChanged;

  final VoidCallback onSeleccionarFecha;
  final VoidCallback onSeleccionarHora;
  final VoidCallback onCambiarRecordatorio;
  final VoidCallback onGuardarCambios;

  const FormularioEvento({
    super.key,
    required this.tituloCtl,
    required this.descCtl,
    required this.fecha,
    required this.hora,
    required this.tema,
    required this.estado,
    required this.visibilidad,
    required this.recordatorioMinutos,
    required this.temas,
    required this.estados,
    required this.visibilidades,
    required this.onTemaChanged,
    required this.onEstadoChanged,
    required this.onVisibilidadChanged,
    required this.onSeleccionarFecha,
    required this.onSeleccionarHora,
    required this.onCambiarRecordatorio,
    required this.onGuardarCambios,
  });

  @override
  Widget build(BuildContext context) {
    final fechaTexto =
        '${fecha.day}/${fecha.month}/${fecha.year} ${hora.format(context)}';

    return Column(
      children: [
        TextField(
          controller: tituloCtl,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        TextField(
          controller: descCtl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text('Fecha y hora: $fechaTexto'),
          onTap: onSeleccionarFecha,
          trailing: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: onSeleccionarHora,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: tema,
          items: temas
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) {
            if (v != null) onTemaChanged(v);
          },
          decoration: const InputDecoration(labelText: 'Tema'),
        ),
        DropdownButtonFormField<String>(
          value: estado,
          items: estados
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onEstadoChanged(v);
          },
          decoration: const InputDecoration(labelText: 'Estado'),
        ),
        DropdownButtonFormField<String>(
          value: visibilidad,
          items: visibilidades
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            if (v != null) onVisibilidadChanged(v);
          },
          decoration: const InputDecoration(labelText: 'Visibilidad'),
        ),
        const SizedBox(height: 10),
        if (recordatorioMinutos != null)
          Text(
            '🔔 Recordatorio actual: $recordatorioMinutos min antes',
            style: const TextStyle(color: Colors.amber),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications),
          label: const Text('Configurar recordatorio'),
          onPressed: onCambiarRecordatorio,
        ),
        const SizedBox(height: 25),
        ElevatedButton.icon(
          onPressed: onGuardarCambios,
          icon: const Icon(Icons.save),
          label: const Text('Guardar cambios'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
      ],
    );
  }
}
