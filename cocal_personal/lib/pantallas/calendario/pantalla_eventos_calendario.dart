import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../servicios/supabase_service.dart';
import 'pantalla_detalle_evento.dart';
import '../../servicios/notificacion_service.dart';

class PantallaEventosCalendario extends StatefulWidget {
  final int idCalendario;
  final String nombreCalendario;

  const PantallaEventosCalendario({
    super.key,  
    required this.idCalendario,
    required this.nombreCalendario,
  });

  @override
  State<PantallaEventosCalendario> createState() =>
      _PantallaEventosCalendarioState();
}

class _PantallaEventosCalendarioState extends State<PantallaEventosCalendario> {
  final _cliente = SupabaseService.cliente;

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  bool _cargando = true;


  String? _temaSeleccionado;
  String? _estadoSeleccionado;
  String _busqueda = '';

  final temasDisponibles = const [
    'MUSICA',
    'PELICULA',
    'VIDEOJUEGOS',
    'ANIME',
    'LITERATURA',
    'DEPORTES'
  ];

  final estadosDisponibles = const ['ACTIVO', 'EN_DESARROLLO', 'INACTIVO'];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _cargarEventos();
  }

  // 🎨 Colores por tema
  Color _colorPorTema(String? tema) {
    switch (tema) {
      case 'MUSICA':
        return Colors.pinkAccent;
      case 'PELICULA':
        return Colors.deepPurpleAccent;
      case 'VIDEOJUEGOS':
        return Colors.teal;
      case 'ANIME':
        return Colors.orangeAccent;
      case 'LITERATURA':
        return Colors.indigo;
      case 'DEPORTES':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cargarEventos() async {
    setState(() => _cargando = true);
    try {
      final res = await _cliente
          .from('evento')
          .select('*')
          .eq('id_calendario', widget.idCalendario)
          .order('horario', ascending: true);

      Map<DateTime, List<Map<String, dynamic>>> mapa = {};
      for (final ev in res) {
        DateTime fecha = DateTime.parse(ev['horario']).toLocal();
        final key = DateTime(fecha.year, fecha.month, fecha.day);
        mapa[key] = mapa[key] ?? [];
        mapa[key]!.add(ev);
      }

      setState(() {
        _eventos = mapa;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al cargar eventos: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  // 🎯 Filtros
  List<Map<String, dynamic>> _getEventosDelDia(DateTime dia) {
    final key = DateTime(dia.year, dia.month, dia.day);
    List<Map<String, dynamic>> lista = _eventos[key] ?? [];

    return lista.where((ev) {
      final coincideTema = _temaSeleccionado == null || ev['tema'] == _temaSeleccionado;
      final coincideEstado =
          _estadoSeleccionado == null || ev['estado'] == _estadoSeleccionado;
      final coincideBusqueda = _busqueda.isEmpty ||
          (ev['titulo'] ?? '').toString().toLowerCase().contains(_busqueda.toLowerCase());
      return coincideTema && coincideEstado && coincideBusqueda;
    }).toList();
  }

Future<void> _crearEvento() async {
  final tituloCtl = TextEditingController();
  final descCtl = TextEditingController();
  DateTime? fechaSeleccionada = DateTime.now();
  TimeOfDay? horaSeleccionada = const TimeOfDay(hour: 9, minute: 0);
  String tema = 'MUSICA';
  String visibilidad = 'PUBLICO';
  String estado = 'ACTIVO';

  await showDialog(
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
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.capitalize())))
                    .toList(),
                onChanged: (v) => tema = v ?? 'MUSICA',
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
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          setStateDialog(() => fechaSeleccionada = fecha);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        fechaSeleccionada != null
                            ? '${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}'
                            : 'Elegir fecha',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: horaSeleccionada ??
                              const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (hora != null) {
                          setStateDialog(() => horaSeleccionada = hora);
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        horaSeleccionada != null
                            ? horaSeleccionada!.format(context)
                            : 'Elegir hora',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () async {
              if (tituloCtl.text.trim().isEmpty ||
                  fechaSeleccionada == null ||
                  horaSeleccionada == null) return;

              final fechaHoraFinal = DateTime(
                fechaSeleccionada!.year,
                fechaSeleccionada!.month,
                fechaSeleccionada!.day,
                horaSeleccionada!.hour,
                horaSeleccionada!.minute,
              );

              final fila = await _cliente
                  .from('evento')
                  .insert({
                    'titulo': tituloCtl.text.trim(),
                    'descripcion': descCtl.text.trim(),
                    'horario': fechaHoraFinal.toIso8601String(),
                    'tema': tema,
                    'estado': estado,
                    'visibilidad': visibilidad,
                    'id_calendario': widget.idCalendario,
                    'creador': 'Usuario Actual',
                  })
                  .select('id, titulo, horario')
                  .single();

              // 🔔 Preguntar si quiere recordatorio
              final activarRecordatorio = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('¿Activar recordatorio?'),
                  content: const Text(
                      '¿Querés que CoCal te avise antes del evento?'),
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

              int? minutosRecordatorio;

              if (activarRecordatorio == true) {
  // ✅ Guardamos el contexto del diálogo principal antes de abrir el nuevo
  final parentContext = context;

  minutosRecordatorio = await showDialog<int>(
    context: context,
    builder: (_) {
      int? valorSeleccionado;
      double personalizado = 15;
      return AlertDialog(
        title: const Text('⏰ Elegí cuándo recordarte'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seleccioná cuánto antes querés el aviso:'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.timer),
                    label: const Text('10 min'),
                    selected: valorSeleccionado == 10,
                    onSelected: (_) => setState(() => valorSeleccionado = 10),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.timer),
                    label: const Text('30 min'),
                    selected: valorSeleccionado == 30,
                    onSelected: (_) => setState(() => valorSeleccionado = 30),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.timer),
                    label: const Text('1 hora'),
                    selected: valorSeleccionado == 60,
                    onSelected: (_) => setState(() => valorSeleccionado = 60),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.edit),
                    label: const Text('Personalizado'),
                    selected: valorSeleccionado == -1,
                    onSelected: (_) => setState(() => valorSeleccionado = -1),
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
                  label: '${personalizado.toInt()} min antes del evento',
                  onChanged: (v) => setState(() => personalizado = v),
                ),
              ],
              const SizedBox(height: 16),

              // ✅ Este es el botón corregido
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar recordatorio'),
                onPressed: () async {
                  final minutos = valorSeleccionado == -1
                      ? personalizado.toInt()
                      : valorSeleccionado ?? 0;

                  if (minutos > 0) {
                    Navigator.pop(context, minutos); // Cierra el diálogo de recordatorio
                    await Future.delayed(const Duration(milliseconds: 200));

                    // 👇 Usamos el contexto del diálogo principal para cerrarlo
                    if (Navigator.canPop(parentContext)) {
                      Navigator.of(parentContext, rootNavigator: true).pop();
                    }

                    // 👇 Refrescamos calendario con el contexto de la pantalla (seguro)
                    if (mounted) {
                      await _cargarEventos();
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: const Text('Evento guardado con recordatorio ✅'),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(10),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  // 🔔 Programa notificación si hace falta
  if (minutosRecordatorio != null && minutosRecordatorio > 0) {
    final fechaEventoLocal = DateTime.parse(fila['horario']).toLocal();
    final fechaRecordatorio =
        fechaEventoLocal.subtract(Duration(minutes: minutosRecordatorio));

    final fechaProgramar = fechaRecordatorio.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(seconds: 2))
        : fechaRecordatorio;

    await NotificacionService.programarNotificacion(
      titulo: '⏰ Recordatorio de evento',
      cuerpo: 'Tu evento "${fila['titulo']}" empieza en $minutosRecordatorio minutos.',
      fecha: fechaProgramar,
    );

    await _cliente
        .from('evento')
        .update({'recordatorio_minutos': minutosRecordatorio})
        .eq('id', fila['id']);
  }
}

              // ✅ Cerrar todo y refrescar una sola vez correctamente
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop(); // cierra todo
                await _cargarEventos();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      activarRecordatorio == true
                          ? 'Evento guardado con recordatorio ✅'
                          : 'Evento guardado correctamente ✅',
                    ),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}




  Future<void> _eliminarEvento(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('¿Seguro que deseas eliminar este evento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (conf != true) return;
    await _cliente.from('evento').delete().eq('id', id);
    await _cargarEventos();
  }

  @override
  Widget build(BuildContext context) {
    final eventosDelDia = _getEventosDelDia(_selectedDay ?? DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('📅 ${widget.nombreCalendario}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearEvento,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventosDelDia,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _busqueda = v),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar evento...',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ...temasDisponibles.map(
                            (t) => FilterChip(
                              label: Text(t.capitalize()),
                              selected: _temaSeleccionado == t,
                              backgroundColor: _colorPorTema(t).withOpacity(0.1),
                              selectedColor: _colorPorTema(t).withOpacity(0.4),
                              onSelected: (v) => setState(
                                () => _temaSeleccionado = v ? t : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: estadosDisponibles.map(
                          (e) => ChoiceChip(
                            label: Text(e.capitalize()),
                            selected: _estadoSeleccionado == e,
                            selectedColor: Colors.indigoAccent,
                            onSelected: (v) =>
                                setState(() => _estadoSeleccionado = v ? e : null),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: eventosDelDia.isEmpty
                      ? const Center(child: Text('No hay eventos en este día.'))
                      : ListView.builder(
                          itemCount: eventosDelDia.length,
                          itemBuilder: (_, i) {
                            final ev = eventosDelDia[i];
                            return Card(
                              color: _colorPorTema(ev['tema']).withOpacity(0.1),
                              margin:
                                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              child: ListTile(
                                title: Text(
                                  ev['titulo'] ?? 'Sin título',
                                  style: TextStyle(
                                    color: _colorPorTema(ev['tema']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${ev['descripcion'] ?? ''}\nEstado: ${ev['estado']}',
                                ),
                                isThreeLine: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PantallaDetalleEvento(
                                        evento: ev,
                                        onGuardado: _cargarEventos,
                                      ),
                                    ),
                                  );
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (ev['recordatorio_minutos'] != null)
                                      Tooltip(
                                        message:
                                            'Recordatorio activo (${ev['recordatorio_minutos']} min antes)',
                                        child: const Icon(Icons.notifications_active, color: Colors.amber),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarEvento(ev['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ✨ Extension auxiliar para capitalizar texto
extension StringX on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
