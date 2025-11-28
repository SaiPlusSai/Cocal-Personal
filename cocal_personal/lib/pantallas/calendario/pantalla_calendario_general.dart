// lib/pantallas/calendario/pantalla_calendario_general.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../servicios/servicio_calendario.dart';
import '../../servicios/social/modelos_grupo.dart';
import '../../servicios/social/grupos_service.dart';

class PantallaCalendarioGeneral extends StatefulWidget {
  final String correo;

  const PantallaCalendarioGeneral({super.key, required this.correo});

  @override
  State<PantallaCalendarioGeneral> createState() =>
      _PantallaCalendarioGeneralState();
}

class _PantallaCalendarioGeneralState
    extends State<PantallaCalendarioGeneral> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _cargando = true;

  List<GrupoResumen> _misGrupos = [];
  int? _grupoSeleccionadoId;
  final Set<DateTime> _diasConCoincidencias = {};

  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};

  @override
  void initState() {
    super.initState();
    debugPrint('[CAL_GENERAL] initState');
    _selectedDay = _focusedDay;
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    debugPrint('[CAL_GENERAL] _cargarTodo()');
    try {
      // 1) grupos del usuario
      final grupos = await GruposService.obtenerMisGrupos();
      debugPrint('[CAL_GENERAL] grupos cargados: ${grupos.length}');

      // 2) eventos propios (calendarios visibles)
      await _cargarEventos();

      setState(() {
        _misGrupos = grupos;
      });
    } catch (e) {
      debugPrint('[CAL_GENERAL] Error en _cargarTodo: $e');
    }
  }

  Future<void> _cargarEventos() async {
    debugPrint('[CAL_GENERAL] _cargarEventos() para ${widget.correo}');
    setState(() => _cargando = true);

    final idUsuario =
    await ServicioCalendario.obtenerUsuarioIdPorCorreo(widget.correo);
    debugPrint('[CAL_GENERAL] idUsuario = $idUsuario');

    if (idUsuario == null) {
      setState(() => _cargando = false);
      return;
    }

    final idsCal =
    await ServicioCalendario.obtenerCalendariosVisiblesDelUsuario(
        idUsuario);
    debugPrint('[CAL_GENERAL] idsCal visibles: $idsCal');

    final desde = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final hasta =
    DateTime(_focusedDay.year, _focusedDay.month + 2, 0, 23, 59);

    final lista = await ServicioCalendario.listarEventosUsuarioEnRango(
      idsCalendario: idsCal,
      desde: desde,
      hasta: hasta,
    );
    debugPrint('[CAL_GENERAL] eventos personales cargados: ${lista.length}');

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
    debugPrint('[CAL_GENERAL] calcularCoincidencias para grupo: $idGrupo');

    if (idGrupo == null) {
      setState(() {}); // limpiar marcas
      return;
    }

    final desde = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final hasta =
    DateTime(_focusedDay.year, _focusedDay.month + 2, 0, 23, 59);

    final eventosGrupo =
    await ServicioCalendario.listarEventosDeGrupoEnRango(
      idGrupo: idGrupo,
      desde: desde,
      hasta: hasta,
    );

    debugPrint(
        '[CAL_GENERAL] eventos de grupo recibidos: ${eventosGrupo.length}');

    // Mapa: (día -> {slotHora -> set<idUsuario>})
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

    const minimoUsuarios = 2; // mínimo para marcar coincidencia

    for (final entry in mapa.entries) {
      final day = entry.key;
      final slots = entry.value;
      final hayCoincidencia =
      slots.values.any((setUsuarios) => setUsuarios.length >= minimoUsuarios);

      if (hayCoincidencia) {
        _diasConCoincidencias.add(day);
      }
    }

    debugPrint(
        '[CAL_GENERAL] días con coincidencias: ${_diasConCoincidencias.length}');
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
                _grupoSeleccionadoId =
                seleccionado ? null : g.id; // deseleccionar si se repite
              });
              await _calcularCoincidenciasGrupoSeleccionado();
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final eventosDelDia = _getEventosDelDia(_selectedDay ?? _focusedDay);

    return Column(
      children: [
        _buildFiltrosGrupos(),
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
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final key = DateTime(day.year, day.month, day.day);
              final tieneCoincidencia = _diasConCoincidencias.contains(key);

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
        const Divider(),
        Expanded(
          child: eventosDelDia.isEmpty
              ? const Center(child: Text('No tienes eventos este día.'))
              : ListView.builder(
            itemCount: eventosDelDia.length,
            itemBuilder: (_, i) {
              final ev = eventosDelDia[i];
              return ListTile(
                title: Text(ev['titulo'] ?? 'Sin título'),
                subtitle: Text(ev['descripcion'] ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }
}
