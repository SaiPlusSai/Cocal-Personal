// lib/pantallas/calendario/dialogos/dialogo_crear_evento.dart
import 'package:flutter/material.dart';
import 'package:cocal_personal/utils/string_extensions.dart';

import '../../../servicios/calendario/servicio_evento.dart';
import '../../../servicios/notificacion_service.dart';

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
              mainAxisSize: MainAxisSize.min,
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
                      .map(
                        (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.capitalize()),
                    ),
                  )
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
                          horaSeleccionada?.format(context) ??
                              'Elegir hora',
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
                    horaSeleccionada == null) {
                  return;
                }

                // 1) Construir fecha/hora final
                final fechaHora = DateTime(
                  fechaSeleccionada!.year,
                  fechaSeleccionada!.month,
                  fechaSeleccionada!.day,
                  horaSeleccionada!.hour,
                  horaSeleccionada!.minute,
                );

                // 2) Crear evento en BD
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

                final int idEvento = fila['id'] as int;
                final String tituloEvento =
                    fila['titulo']?.toString() ?? 'Evento';
                final DateTime fechaEvento =
                DateTime.parse(fila['horario'] as String).toLocal();

                // 3) Preguntar si quiere recordatorio
                final activar = await _preguntarActivarRecordatorio(context);

                if (activar == true) {
                  // 4) Mostrar diálogo para elegir minutos
                  final minutos = await _pedirMinutosRecordatorio(context);

                  if (minutos != null && minutos > 0) {
                    // 5) Guardar recordatorio_minutos en BD
                    await ServicioEvento.actualizarRecordatorio(
                      idEvento: idEvento,
                      minutos: minutos,
                    );

                    // 6) Calcular cuándo disparar notificación
                    final fechaRecordatorio = fechaEvento.subtract(
                      Duration(minutes: minutos),
                    );

                    final fechaProgramar =
                    fechaRecordatorio.isBefore(DateTime.now())
                        ? DateTime.now()
                        .add(const Duration(seconds: 2))
                        : fechaRecordatorio;

                    await NotificacionService.programarNotificacion(
                      titulo: '⏰ Recordatorio de evento',
                      cuerpo:
                      'Tu evento "$tituloEvento" empieza en $minutos minutos.',
                      fecha: fechaProgramar,
                    );
                  }
                }

                // 7) Cerrar el diálogo principal y notificar al caller
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

  /// Diálogo simple Sí/No: ¿activar recordatorio?
  static Future<bool?> _preguntarActivarRecordatorio(
      BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Activar recordatorio?'),
        content: const Text('¿Querés que CoCal te avise antes del evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para elegir minutos (10, 30, 60 o personalizado con slider)
  static Future<int?> _pedirMinutosRecordatorio(
      BuildContext context) async {
    int? valorSeleccionado;
    double personalizado = 15;

    return showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('⏰ Elegí cuándo recordarte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Seleccioná cuánto antes querés el aviso:'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.timer),
                    label: const Text('10 min'),
                    selected: valorSeleccionado == 10,
                    onSelected: (_) =>
                        setStateDialog(() => valorSeleccionado = 10),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.timer),
                    label: const Text('30 min'),
                    selected: valorSeleccionado == 30,
                    onSelected: (_) =>
                        setStateDialog(() => valorSeleccionado = 30),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.timer),
                    label: const Text('1 hora'),
                    selected: valorSeleccionado == 60,
                    onSelected: (_) =>
                        setStateDialog(() => valorSeleccionado = 60),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.edit),
                    label: const Text('Personalizado'),
                    selected: valorSeleccionado == -1,
                    onSelected: (_) =>
                        setStateDialog(() => valorSeleccionado = -1),
                  ),
                ],
              ),
              if (valorSeleccionado == -1) ...[
                const SizedBox(height: 16),
                const Text('Definí minutos personalizados:'),
                Slider(
                  min: 5,
                  max: 120,
                  divisions: 23,
                  value: personalizado,
                  label:
                  '${personalizado.toInt()} min antes del evento',
                  onChanged: (v) =>
                      setStateDialog(() => personalizado = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar recordatorio'),
              onPressed: () {
                final minutos = valorSeleccionado == -1
                    ? personalizado.toInt()
                    : (valorSeleccionado ?? 0);

                if (minutos <= 0) {
                  Navigator.pop(context, null);
                } else {
                  Navigator.pop(context, minutos);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
