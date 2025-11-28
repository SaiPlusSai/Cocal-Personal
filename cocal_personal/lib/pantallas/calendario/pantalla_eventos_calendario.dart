//lib/pantallas/calendario/pantalla_eventos_calendario.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../servicios/calendario/servicio_calendario.dart';
import '../../servicios/calendario/servicio_evento.dart';
import 'dialogos/dialogo_crear_evento.dart';
import 'dialogos/dialogo_confirmar_eliminacion.dart';

import 'pantalla_detalle_evento.dart';
import 'widgets/evento_card.dart';
import 'widgets/filtros_eventos.dart';

class PantallaEventosCalendario extends StatefulWidget {
  final int idCalendario;
  final String nombreCalendario;
  final int? idGrupo;

  const PantallaEventosCalendario({
    super.key,  
    required this.idCalendario,
    required this.nombreCalendario,
    this.idGrupo,
  });

  @override
  State<PantallaEventosCalendario> createState() =>
      _PantallaEventosCalendarioState();
}

class _PantallaEventosCalendarioState extends State<PantallaEventosCalendario> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  bool _cargando = true;

  CalendarFormat _calendarFormat = CalendarFormat.month;

  final temasDisponibles = const [
    'MUSICA',
    'PELICULA',
    'VIDEOJUEGOS',
    'ANIME',
    'LITERATURA',
    'DEPORTES',
  ];

  final estadosDisponibles = const ['ACTIVO', 'EN_DESARROLLO', 'INACTIVO'];

  String? _temaSeleccionado;
  String? _estadoSeleccionado;
  String _busqueda = '';

  final Set<DateTime> _diasConCoincidenciasGrupo = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _cargarEventos();
    if (widget.idGrupo != null) {
      _calcularCoincidenciasGrupo();
    }
  }

  Color _colorPorTema(String? tema) {
    switch (tema) {
      case 'MUSICA':
        return Colors.indigo;
      case 'PELICULA':
        return Colors.deepPurple;
      case 'VIDEOJUEGOS':
        return Colors.teal;
      case 'ANIME':
        return Colors.pinkAccent;
      case 'LITERATURA':
        return Colors.brown;
      case 'DEPORTES':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }


  Future<void> _cargarEventos() async {
    setState(() => _cargando = true);
    try {
      final res = await ServicioEvento.listarEventosDeCalendario(
        widget.idCalendario,
      );

      final mapa = <DateTime, List<Map<String, dynamic>>>{};
      for (final ev in res) {
        final fecha = DateTime.parse(ev['horario']).toLocal();
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

  Future<void> _calcularCoincidenciasGrupo() async {
    _diasConCoincidenciasGrupo.clear();

    final idGrupo = widget.idGrupo;
    if (idGrupo == null) return;

    final desde = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final hasta =
    DateTime(_focusedDay.year, _focusedDay.month + 2, 0, 23, 59);

    final eventosGrupo =
    await ServicioCalendario.listarEventosDeGrupoEnRango(
      idGrupo: idGrupo,
      desde: desde,
      hasta: hasta,
    );

    final Map<DateTime, Map<int, Set<int>>> mapa = {};

    for (final ev in eventosGrupo) {
      final fecha = DateTime.parse(ev['horario']).toLocal();
      final dayKey = DateTime(fecha.year, fecha.month, fecha.day);
      final slot = fecha.hour;
      final idUsuario = ev['id_usuario'] as int;

      mapa.putIfAbsent(dayKey, () => {});
      mapa[dayKey]!.putIfAbsent(slot, () => <int>{});
      mapa[dayKey]![slot]!.add(idUsuario);
    }

    const minimoUsuarios = 2;

    for (final entry in mapa.entries) {
      final day = entry.key;
      final slots = entry.value;
      final hayCoincidencia =
      slots.values.any((setUsuarios) => setUsuarios.length >= minimoUsuarios);
      if (hayCoincidencia) {
        _diasConCoincidenciasGrupo.add(day);
      }
    }

    setState(() {});
  }

  List<Map<String, dynamic>> _getEventosDelDia(DateTime dia) {
    final key = DateTime(dia.year, dia.month, dia.day);
    final lista = _eventos[key] ?? [];

    return lista.where((ev) {
      final coincideTema =
          _temaSeleccionado == null || ev['tema'] == _temaSeleccionado;
      final coincideEstado =
          _estadoSeleccionado == null || ev['estado'] == _estadoSeleccionado;
      final coincideBusqueda = _busqueda.isEmpty ||
          (ev['titulo'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_busqueda.toLowerCase());
      return coincideTema && coincideEstado && coincideBusqueda;
    }).toList();
  }

  Future<void> _importarDesdeCalendarioPersonal() async {
    String categoriaSeleccionada = temasDisponibles.first;

    final cat = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importar eventos por categoría'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) => DropdownButtonFormField<String>(
            value: categoriaSeleccionada,
            items: temasDisponibles
                .map(
                  (t) => DropdownMenuItem(
                value: t,
                child: Text(t),
              ),
            )
                .toList(),
            onChanged: (v) => setStateDialog(
                  () => categoriaSeleccionada = v ?? categoriaSeleccionada,
            ),
            decoration: const InputDecoration(
              labelText: 'Categoría',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, categoriaSeleccionada),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (cat == null) return;

    final error =
    await ServicioCalendario.copiarEventosDeCategoriaACalendarioDestino(
      idCalendarioDestino: widget.idCalendario,
      categoria: cat,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      await _cargarEventos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Eventos de categoría "$cat" importados desde tu calendario personal ✅',
          ),
        ),
      );
    }
  }
  Future<void> _crearEvento() async {
    final creado = await DialogoCrearEvento.mostrar(
      context: context,
      idCalendario: widget.idCalendario,
      temasDisponibles: temasDisponibles,
      onEventoCreado: _cargarEventos,
    );

    if (creado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento creado correctamente ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _eliminarEvento(int id) async {
    final confirmar = await DialogoConfirmarEliminacion.mostrar(context);
    if (!confirmar) return;

    await ServicioEvento.eliminarEvento(id);
    await _cargarEventos();
  }


  @override
  Widget build(BuildContext context) {
    final eventosDelDia = _getEventosDelDia(_selectedDay ?? DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('📅 ${widget.nombreCalendario}'),
        actions: [
          if (widget.idGrupo != null)
            IconButton(
              tooltip: 'Importar eventos por categoría',
              icon: const Icon(Icons.download),
              onPressed: _importarDesdeCalendarioPersonal,
            ),
        ],
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
            onPageChanged: (focused) {
              _focusedDay = focused;
              if (widget.idGrupo != null) {
                _calcularCoincidenciasGrupo(); // recalcular al cambiar de mes
              }
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                // Solo marcamos si estamos viendo esto como calendario de grupo
                if (widget.idGrupo == null) return null;

                final key = DateTime(day.year, day.month, day.day);
                final tieneCoincidencia =
                _diasConCoincidenciasGrupo.contains(key);

                if (!tieneCoincidencia) return null;

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          FiltrosEventosCalendario(
            temasDisponibles: temasDisponibles,
            estadosDisponibles: estadosDisponibles,
            temaSeleccionado: _temaSeleccionado,
            estadoSeleccionado: _estadoSeleccionado,
            busqueda: _busqueda,
            onBusquedaChanged: (v) => setState(() => _busqueda = v),
            onTemaChanged: (t) =>
                setState(() => _temaSeleccionado = t),
            onEstadoChanged: (e) =>
                setState(() => _estadoSeleccionado = e),
            colorPorTema: _colorPorTema,
          ),
          const Divider(),
          Expanded(
            child: eventosDelDia.isEmpty
                ? const Center(
              child: Text('No hay eventos en este día.'),
            )
                : ListView.builder(
              itemCount: eventosDelDia.length,
              itemBuilder: (_, i) {
                final ev = eventosDelDia[i];
                return EventoCard(
                  evento: ev,
                  colorPorTema: _colorPorTema,
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
                  onDelete: () => _eliminarEvento(ev['id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
