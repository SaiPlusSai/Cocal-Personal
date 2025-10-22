import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../servicios/supabase_service.dart';
import 'pantalla_detalle_evento.dart';

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

  // 🔍 filtros
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
        SnackBar(content: Text('Error al cargar eventos: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> _getEventosDelDia(DateTime dia) {
    final key = DateTime(dia.year, dia.month, dia.day);
    List<Map<String, dynamic>> lista = _eventos[key] ?? [];

    // 🎯 Aplicar filtros
    return lista.where((ev) {
      final coincideTema = _temaSeleccionado == null ||
          ev['tema'] == _temaSeleccionado;
      final coincideEstado = _estadoSeleccionado == null ||
          ev['estado'] == _estadoSeleccionado;
      final coincideBusqueda = _busqueda.isEmpty ||
          (ev['titulo'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_busqueda.toLowerCase());
      return coincideTema && coincideEstado && coincideBusqueda;
    }).toList();
  }

  Future<void> _crearEvento() async {
    final tituloCtl = TextEditingController();
    final descCtl = TextEditingController();
    DateTime? fechaSeleccionada = DateTime.now();
    String tema = 'MUSICA';
    String visibilidad = 'PUBLICO';
    String estado = 'ACTIVO';

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
                items: temasDisponibles
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.capitalize())))
                    .toList(),
                onChanged: (v) => tema = v ?? 'MUSICA',
                decoration: const InputDecoration(labelText: 'Tema'),
              ),
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
              DropdownButtonFormField<String>(
                value: estado,
                items: estadosDisponibles
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.capitalize())))
                    .toList(),
                onChanged: (v) => estado = v ?? 'ACTIVO',
                decoration: const InputDecoration(labelText: 'Estado'),
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
                'estado': estado,
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
                // 📆 CALENDARIO
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

                // 🧠 FILTROS
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

                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _eliminarEvento(ev['id']),
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
