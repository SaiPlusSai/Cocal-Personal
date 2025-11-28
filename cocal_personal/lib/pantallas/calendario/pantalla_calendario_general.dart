import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../servicios/calendario/servicio_calendario.dart';
import '../../servicios/social/modelos_grupo.dart';
import '../../servicios/social/grupos_service.dart';
import 'dialogos/dialogo_crear_evento.dart';
import 'pantalla_detalle_evento.dart';

class PantallaCalendarioGeneral extends StatefulWidget {
  final String correo;

  const PantallaCalendarioGeneral({super.key, required this.correo});

  @override
  State<PantallaCalendarioGeneral> createState() =>
      _PantallaCalendarioGeneralState();
}

class _PantallaCalendarioGeneralState extends State<PantallaCalendarioGeneral> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _cargando = true;

  List<GrupoResumen> _misGrupos = [];
  int? _grupoSeleccionadoId;
  final Set<DateTime> _diasConCoincidencias = {};
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};

  CalendarFormat _calendarFormat = CalendarFormat.month;

  final List<String> _temasDisponibles = const [
    'MUSICA',
    'PELICULA',
    'VIDEOJUEGOS',
    'ANIME',
    'LITERATURA',
    'DEPORTES',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    try {
      final grupos = await GruposService.obtenerMisGrupos();
      await _cargarEventos();

      setState(() {
        _misGrupos = grupos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarEventos() async {
    setState(() => _cargando = true);

    final idUsuario =
    await ServicioCalendario.obtenerUsuarioIdPorCorreo(widget.correo);

    if (idUsuario == null) {
      setState(() => _cargando = false);
      return;
    }

    final idsCal =
    await ServicioCalendario.obtenerCalendariosVisiblesDelUsuario(
        idUsuario);

    final desde = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final hasta = DateTime(
      _focusedDay.year,
      _focusedDay.month + 2,
      0,
      23,
      59,
    );

    final lista = await ServicioCalendario.listarEventosUsuarioEnRango(
      idsCalendario: idsCal,
      desde: desde,
      hasta: hasta,
    );

    final mapa = <DateTime, List<Map<String, dynamic>>>{};
    for (final ev in lista) {
      final fecha = DateTime.parse(ev['horario']).toLocal();
      final key = DateTime(fecha.year, fecha.month, fecha.day);
      (mapa[key] ??= []).add(ev);
    }

    setState(() {
      _eventos = mapa;
      _cargando = false;
      _selectedDay ??= _focusedDay;
    });
  }

  Future<void> _calcularCoincidenciasGrupoSeleccionado() async {
    _diasConCoincidencias.clear();

    final idGrupo = _grupoSeleccionadoId;
    if (idGrupo == null) {
      setState(() {});
      return;
    }

    final desde = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final hasta = DateTime(
      _focusedDay.year,
      _focusedDay.month + 2,
      0,
      23,
      59,
    );

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
        _diasConCoincidencias.add(day);
      }
    }

    setState(() {});
  }

  List<Map<String, dynamic>> _getEventosDelDia(DateTime dia) {
    final key = DateTime(dia.year, dia.month, dia.day);
    return _eventos[key] ?? [];
  }

  Widget _buildFiltrosGrupos() {
    if (_misGrupos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: _misGrupos.map((g) {
          final seleccionado = _grupoSeleccionadoId == g.id;
          return ChoiceChip(
            label: Text(g.nombre),
            selected: seleccionado,
            onSelected: (_) async {
              setState(() {
                _grupoSeleccionadoId = seleccionado ? null : g.id;
              });
              await _calcularCoincidenciasGrupoSeleccionado();
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _crearNuevoEvento() async {
    try {
      final idUsuario =
      await ServicioCalendario.obtenerUsuarioIdPorCorreo(widget.correo);

      if (idUsuario == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el usuario actual'),
          ),
        );
        return;
      }

      final calPersonal =
      await ServicioCalendario.obtenerOCrearCalendarioPersonal(idUsuario);

      if (calPersonal == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener/crear tu calendario personal'),
          ),
        );
        return;
      }

      final base = _selectedDay ?? _focusedDay;
      final fechaInicial = DateTime(base.year, base.month, base.day);

      final creado = await DialogoCrearEvento.mostrar(
        context: context,
        idCalendario: calPersonal.id,
        temasDisponibles: _temasDisponibles,
        fechaInicial: fechaInicial,
        onEventoCreado: _cargarEventos,
      );

      if (creado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento creado correctamente ✅'),
            backgroundColor: Colors.green,
          ),
        );
        await _calcularCoincidenciasGrupoSeleccionado();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al crear evento: $e'),
        ),
      );
    }
  }

  /// Celda para el calendario general: días con eventos pintados y
  /// coincidencias de grupo resaltadas.
  Widget _buildDayCell(
      BuildContext context,
      DateTime day,
      DateTime focusedDay, {
        bool isSelected = false,
        bool isToday = false,
      }) {
    final events = _getEventosDelDia(day);
    final key = DateTime(day.year, day.month, day.day);

    final hayEventos = events.isNotEmpty;
    final tieneCoincidencia = _diasConCoincidencias.contains(key);

    Color bgColor = Colors.transparent;

    if (hayEventos) {
      // Color suave si solo son tus eventos
      bgColor = Colors.indigo.withOpacity(0.18);
    }

    if (tieneCoincidencia) {
      // Aumentamos la intensidad para marcar la coincidencia del grupo
      bgColor = Colors.orange.withOpacity(hayEventos ? 0.35 : 0.25);
    }

    Border? border;
    if (isSelected) {
      border = Border.all(color: Colors.deepPurple, width: 2);
    } else if (isToday) {
      border = Border.all(color: Colors.indigo, width: 1.5);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontWeight: hayEventos ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final eventosDelDia = _getEventosDelDia(_selectedDay ?? _focusedDay);

    return Stack(
      children: [
        Column(
          children: [
            _buildFiltrosGrupos(),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ChoiceChip(
                    label: const Text('Mes'),
                    selected: _calendarFormat == CalendarFormat.month,
                    onSelected: (_) {
                      setState(() => _calendarFormat = CalendarFormat.month);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Semana'),
                    selected: _calendarFormat == CalendarFormat.week,
                    onSelected: (_) {
                      setState(() => _calendarFormat = CalendarFormat.week);
                    },
                  ),
                ],
              ),
            ),
            TableCalendar(
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.week: 'Semana',
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
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
                _cargarEventos();
                _calcularCoincidenciasGrupoSeleccionado();
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) =>
                    _buildDayCell(context, day, focusedDay),
                todayBuilder: (context, day, focusedDay) =>
                    _buildDayCell(context, day, focusedDay, isToday: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _buildDayCell(context, day, focusedDay, isSelected: true),
              ),
            ),
            const Divider(),
            Expanded(
              child: eventosDelDia.isEmpty
                  ? const Center(
                child: Text('No tienes eventos este día.'),
              )
                  : ListView.builder(
                itemCount: eventosDelDia.length,
                itemBuilder: (_, i) {
                  final ev = eventosDelDia[i];
                  final creador =
                      ev['creador']?.toString() ?? 'Desconocido';
                  final fecha =
                  DateTime.parse(ev['horario']).toLocal();
                  final hora =
                  TimeOfDay.fromDateTime(fecha).format(context);

                  final descripcion = (ev['descripcion'] ?? '').toString();

                  return ListTile(
                    title: Text(ev['titulo'] ?? 'Sin título'),
                    subtitle: Text(
                      [
                        if (descripcion.isNotEmpty) descripcion,
                        'Hora: $hora',
                        'Creado por: $creador',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaDetalleEvento(
                            evento: ev,
                            onGuardado: () async {
                              await _cargarEventos();
                              await _calcularCoincidenciasGrupoSeleccionado();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _crearNuevoEvento,
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
