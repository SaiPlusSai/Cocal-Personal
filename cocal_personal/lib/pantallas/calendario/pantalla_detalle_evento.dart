import 'package:flutter/material.dart';
import '../../servicios/supabase_service.dart';
import '../../servicios/notificacion_service.dart';

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
    'DEPORTES'
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
        SnackBar(content: Text('🔔 Recordatorio ajustado a $minutos minutos antes')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto =
        '${_fecha.day}/${_fecha.month}/${_fecha.year} ${_hora.format(context)}';

    return Scaffold(
      appBar: AppBar(title: const Text('✏️ Editar evento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _tituloCtl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: _descCtl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Fecha y hora: $fechaTexto'),
                onTap: _seleccionarFecha,
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _seleccionarHora,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tema,
                items: temas
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tema = v ?? _tema),
                decoration: const InputDecoration(labelText: 'Tema'),
              ),
              DropdownButtonFormField<String>(
                value: _estado,
                items: estados
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _estado = v ?? _estado),
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              DropdownButtonFormField<String>(
                value: _visibilidad,
                items: visibilidades
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _visibilidad = v ?? _visibilidad),
                decoration: const InputDecoration(labelText: 'Visibilidad'),
              ),
              const SizedBox(height: 10),
              if (_recordatorioMinutos != null)
                Text(
                  '🔔 Recordatorio actual: $_recordatorioMinutos min antes',
                  style: const TextStyle(color: Colors.amber),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.notifications),
                label: const Text('Configurar recordatorio'),
                onPressed: _cambiarRecordatorio,
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _guardarCambios,
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
