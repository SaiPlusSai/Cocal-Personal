import 'package:flutter/material.dart';
import '../../../servicios/calendario/servicio_evento.dart';
import '../../../servicios/notificacion_service.dart';
import 'package:cocal_personal/utils/string_extensions.dart';

class DialogoCrearEvento {
  static Future<bool> mostrar({
    required BuildContext context,
    required int idCalendario,
    required List<String> temasDisponibles,
    VoidCallback? onEventoCreado,
  }) async {
    final tituloCtl = TextEditingController();
    final descCtl = TextEditingController();
    DateTime? fechaSeleccionada = DateTime.now();
    TimeOfDay? horaSeleccionada = const TimeOfDay(hour: 9, minute: 0);

    String tema = temasDisponibles.first;
    String visibilidad = 'PUBLICO';
    String estado = 'ACTIVO';

    final creado = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('➕ Nuevo evento'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: tituloCtl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tema,
                  items: temasDisponibles
                      .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.capitalize()),
                  ))
                      .toList(),
                  onChanged: (v) => tema = v ?? tema,
                  decoration: const InputDecoration(
                    labelText: 'Tema',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          fechaSeleccionada == null
                              ? 'Elegir fecha'
                              : '${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}',
                        ),
                        onPressed: () async {
                          final f = await showDatePicker(
                            context: context,
                            initialDate:
                            fechaSeleccionada ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (f != null) {
                            setStateDialog(() => fechaSeleccionada = f);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          horaSeleccionada?.format(context) ?? 'Elegir hora',
                        ),
                        onPressed: () async {
                          final h = await showTimePicker(
                            context: context,
                            initialTime: horaSeleccionada ??
                                const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (h != null) {
                            setStateDialog(() => horaSeleccionada = h);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (tituloCtl.text.trim().isEmpty ||
                    fechaSeleccionada == null ||
                    horaSeleccionada == null) return;

                final fechaHora = DateTime(
                  fechaSeleccionada!.year,
                  fechaSeleccionada!.month,
                  fechaSeleccionada!.day,
                  horaSeleccionada!.hour,
                  horaSeleccionada!.minute,
                );

                final fila = await ServicioEvento.crearEvento(
                  titulo: tituloCtl.text.trim(),
                  descripcion: descCtl.text.trim(),
                  horario: fechaHora,
                  tema: tema,
                  estado: estado,
                  visibilidad: visibilidad,
                  idCalendario: idCalendario,
                  creador: 'Usuario Actual',
                );

                final activar = await showDialog<bool>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('¿Activar recordatorio?'),
                    actions: [
                      TextButton(child: Text('No'), onPressed: null),
                      ElevatedButton(child: Text('Sí'), onPressed: null),
                    ],
                  ),
                );

                if (activar == true) {
                  // aquí podrías reutilizar otro diálogo de recordatorio
                }

                Navigator.pop(context, true);
                onEventoCreado?.call();
              },
            ),
          ],
        ),
      ),
    );

    return creado ?? false;
  }
}
