import 'package:flutter/material.dart';
import '../../servicios/supabase_service.dart';

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
  String _tema = 'MUSICA';
  String _estado = 'ACTIVO';
  String _visibilidad = 'PUBLICO';

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
    _fecha = DateTime.parse(widget.evento['horario']).toLocal();
  }

  Future<void> _guardarCambios() async {
    try {
      await _cliente.from('evento').update({
        'titulo': _tituloCtl.text.trim(),
        'descripcion': _descCtl.text.trim(),
        'horario': _fecha.toUtc().toIso8601String(),
        'tema': _tema,
        'estado': _estado,
        'visibilidad': _visibilidad,
      }).eq('id', widget.evento['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Evento actualizado')),
      );
      widget.onGuardado();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
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
                title: Text('Fecha: ${_fecha.toLocal().toString().split(' ')[0]}'),
                onTap: _seleccionarFecha,
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
