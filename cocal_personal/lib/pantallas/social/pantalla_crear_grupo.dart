import 'package:flutter/material.dart';
import '../../servicios/social/grupos_service.dart';

class PantallaCrearGrupo extends StatefulWidget {
  const PantallaCrearGrupo({super.key});

  @override
  State<PantallaCrearGrupo> createState() => _PantallaCrearGrupoState();
}

class _PantallaCrearGrupoState extends State<PantallaCrearGrupo> {
  final _nombreCtl = TextEditingController();
  final _descCtl = TextEditingController();
  String _visibilidad = 'PUBLICO';
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un nombre para el grupo')),
      );
      return;
    }

    setState(() => _cargando = true);
    final err = await GruposService.crearGrupo(
      nombre: nombre,
      descripcion: _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      visibilidad: _visibilidad,
    );
    setState(() => _cargando = false);

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grupo creado correctamente')),
    );
    Navigator.pop(context, true); // devolvemos "creado = true"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo grupo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nombreCtl,
              decoration: const InputDecoration(
                labelText: 'Nombre del grupo',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const Text('Visibilidad'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _visibilidad,
              items: const [
                DropdownMenuItem(
                  value: 'PUBLICO',
                  child: Text('Público'),
                ),
                DropdownMenuItem(
                  value: 'PRIVADO',
                  child: Text('Privado'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _visibilidad = val);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Crear grupo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
