import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../servicios/supabase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _cargarEventos();
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
        SnackBar(content: Text('Error al cargar eventos: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> _getEventosDelDia(DateTime dia) {
    final key = DateTime(dia.year, dia.month, dia.day);
    return _eventos[key] ?? [];
  }

  Future<void> _crearEvento() async {
    final tituloCtl = TextEditingController();
    final descCtl = TextEditingController();
    DateTime? fechaSeleccionada = DateTime.now();
    String tema = 'MUSICA';
    String visibilidad = 'PUBLICO';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('➕ Nuevo evento'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: tituloCtl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descCtl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: tema,
                items: const [
                  DropdownMenuItem(value: 'MUSICA', child: Text('Música')),
                  DropdownMenuItem(value: 'DEPORTES', child: Text('Deportes')),
                  DropdownMenuItem(value: 'VIDEOJUEGOS', child: Text('Videojuegos')),
                  DropdownMenuItem(value: 'ANIME', child: Text('Anime')),
                  DropdownMenuItem(value: 'LITERATURA', child: Text('Literatura')),
                ],
                onChanged: (v) => tema = v ?? 'MUSICA',
                decoration: const InputDecoration(labelText: 'Tema'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: visibilidad,
                items: const [
                  DropdownMenuItem(value: 'PUBLICO', child: Text('Público')),
                  DropdownMenuItem(value: 'PRIVADO', child: Text('Privado')),
                  DropdownMenuItem(value: 'GRUPO', child: Text('Grupo')),
                ],
                onChanged: (v) => visibilidad = v ?? 'PUBLICO',
                decoration: const InputDecoration(labelText: 'Visibilidad'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (fecha != null) fechaSeleccionada = fecha;
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Elegir fecha'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (tituloCtl.text.trim().isEmpty) return;

              await _cliente.from('evento').insert({
                'titulo': tituloCtl.text.trim(),
                'descripcion': descCtl.text.trim(),
                'horario': fechaSeleccionada?.toUtc().toIso8601String(),
                'tema': tema,
                'visibilidad': visibilidad,
                'id_calendario': widget.idCalendario,
                'creador': 'Usuario Actual',
              });

              if (!mounted) return;
              Navigator.pop(context);
              await _cargarEventos();
            },
            child: const Text('Guardar'),
          ),
        ],
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
                const Divider(),
                Expanded(
                  child: _getEventosDelDia(_selectedDay ?? DateTime.now()).isEmpty
                      ? const Center(child: Text('No hay eventos en este día.'))
                      : ListView(
                          children: _getEventosDelDia(_selectedDay ?? DateTime.now())
                              .map((ev) => Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    child: ListTile(
                                      title: Text(ev['titulo']),
                                      subtitle: Text(ev['descripcion'] ?? ''),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _eliminarEvento(ev['id']),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
    );
  }
}
