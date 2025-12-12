//lib/pantallas/calendario/pantalla_detalle_evento.dart
import 'package:flutter/material.dart';
import '../../servicios/supabase_service.dart';
import '../../servicios/notificacion_service.dart';
import '../../servicios/calendario/servicio_evento.dart';
import 'widgets/formulario_evento.dart';
import 'widgets/conversacion_evento.dart';

class PantallaDetalleEvento extends StatefulWidget {
  final Map<String, dynamic> evento;
  final VoidCallback onGuardado;

  const PantallaDetalleEvento({
    super.key,
    required this.evento,
    required this.onGuardado,
  });

  @override
  State<PantallaDetalleEvento> createState() => _PantallaDetalleEventoState();
}

class _PantallaDetalleEventoState extends State<PantallaDetalleEvento> {
  final _cliente = SupabaseService.cliente;

  late TextEditingController _tituloCtl;
  late TextEditingController _descCtl;
  late DateTime _fecha;
  late TimeOfDay _hora;
  String _tema = 'MUSICA';
  String _estado = 'ACTIVO';
  String _visibilidad = 'PUBLICO';
  int? _recordatorioMinutos;

  final temas = const [
    'MUSICA',
    'PELICULA',
    'VIDEOJUEGOS',
    'ANIME',
    'LITERATURA',
    'DEPORTES',
  ];
  final estados = const ['ACTIVO', 'EN_DESARROLLO', 'INACTIVO'];
  final visibilidades = const ['PUBLICO', 'PRIVADO', 'GRUPO'];

  @override
  void initState() {
    super.initState();
    _tituloCtl = TextEditingController(text: widget.evento['titulo']);
    _descCtl = TextEditingController(text: widget.evento['descripcion']);
    _tema = widget.evento['tema'] ?? 'MUSICA';
    _estado = widget.evento['estado'] ?? 'ACTIVO';
    _visibilidad = widget.evento['visibilidad'] ?? 'PUBLICO';
    _recordatorioMinutos = widget.evento['recordatorio_minutos'];

    final fechaHora = DateTime.parse(widget.evento['horario']).toLocal();
    _fecha = DateTime(fechaHora.year, fechaHora.month, fechaHora.day);
    _hora = TimeOfDay(hour: fechaHora.hour, minute: fechaHora.minute);
  }

  Future<void> _seleccionarFecha() async {
    final nueva = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (nueva != null) setState(() => _fecha = nueva);
  }

  Future<void> _seleccionarHora() async {
    final nueva = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (nueva != null) setState(() => _hora = nueva);
  }

  Future<void> _guardarCambios() async {
    try {
      final fechaHoraFinal = DateTime(
        _fecha.year,
        _fecha.month,
        _fecha.day,
        _hora.hour,
        _hora.minute,
      );

      await _cliente.from('evento').update({
        'titulo': _tituloCtl.text.trim(),
        'descripcion': _descCtl.text.trim(),
        'horario': fechaHoraFinal.toIso8601String(),
        'tema': _tema,
        'estado': _estado,
        'visibilidad': _visibilidad,
        'recordatorio_minutos': _recordatorioMinutos,
      }).eq('id', widget.evento['id']);

      // Si hay recordatorio, reprogramar notificación
      if (_recordatorioMinutos != null && _recordatorioMinutos! > 0) {
        final recordatorio = fechaHoraFinal.subtract(
          Duration(minutes: _recordatorioMinutos!),
        );

        final fechaProgramar = recordatorio.isBefore(DateTime.now())
            ? DateTime.now().add(const Duration(seconds: 2))
            : recordatorio;

        await NotificacionService.programarNotificacion(
          titulo: '⏰ Recordatorio actualizado',
          cuerpo:
          'Tu evento "${_tituloCtl.text}" empieza en $_recordatorioMinutos minutos.',
          fecha: fechaProgramar,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Evento actualizado correctamente')),
      );
      widget.onGuardado();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al guardar: $e')),
      );
    }
  }

  Future<void> _cambiarRecordatorio() async {
    final personalizadoCtl = TextEditingController();
    int? valorSeleccionado;

    final minutos = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔔 Configurar recordatorio'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Elegí cuánto antes querés que se te avise:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('10 min'),
                    selected: valorSeleccionado == 10,
                    onSelected: (_) => setState(() => valorSeleccionado = 10),
                  ),
                  ChoiceChip(
                    label: const Text('30 min'),
                    selected: valorSeleccionado == 30,
                    onSelected: (_) => setState(() => valorSeleccionado = 30),
                  ),
                  ChoiceChip(
                    label: const Text('1 hora'),
                    selected: valorSeleccionado == 60,
                    onSelected: (_) => setState(() => valorSeleccionado = 60),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: personalizadoCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Otro (minutos personalizados)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (personalizadoCtl.text.isNotEmpty) {
                    final val = int.tryParse(personalizadoCtl.text);
                    if (val != null && val > 0) {
                      Navigator.pop(context, val);
                      return;
                    }
                  }
                  Navigator.pop(context, valorSeleccionado);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (minutos != null && minutos > 0) {
      setState(() => _recordatorioMinutos = minutos);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Recordatorio ajustado a $minutos minutos antes'),
        ),
      );
    }
  }

  Future<void> _eliminarEvento() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('¿Seguro que deseas eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ServicioEvento.eliminarEvento(widget.evento['id'] as int);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Evento eliminado')),
      );

      widget.onGuardado();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ Editar evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _eliminarEvento,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              FormularioEvento(
                tituloCtl: _tituloCtl,
                descCtl: _descCtl,
                fecha: _fecha,
                hora: _hora,
                tema: _tema,
                estado: _estado,
                visibilidad: _visibilidad,
                recordatorioMinutos: _recordatorioMinutos,
                temas: temas,
                estados: estados,
                visibilidades: visibilidades,
                onTemaChanged: (v) => setState(() => _tema = v),
                onEstadoChanged: (v) => setState(() => _estado = v),
                onVisibilidadChanged: (v) =>
                    setState(() => _visibilidad = v),
                onSeleccionarFecha: _seleccionarFecha,
                onSeleccionarHora: _seleccionarHora,
                onCambiarRecordatorio: _cambiarRecordatorio,
                onGuardarCambios: _guardarCambios,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              ConversacionEvento(
                eventoId: widget.evento['id'] as int,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
