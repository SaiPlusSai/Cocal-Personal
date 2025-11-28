//lib/pantallas/calendario/pantalla_calendarios.dart
import 'package:flutter/material.dart';
import '../../servicios/servicio_calendario.dart';
import 'pantalla_eventos_calendario.dart';
class PantallaCalendarios extends StatefulWidget {
  final String correo;

  const PantallaCalendarios({super.key, required this.correo});

  @override
  State<PantallaCalendarios> createState() => _PantallaCalendariosState();
}

class _PantallaCalendariosState extends State<PantallaCalendarios> {
  int? _idUsuario;
  bool _cargando = true;
  List<Map<String, dynamic>> _calendarios = [];

  final _nombreCtl = TextEditingController();
  String _zonaHoraria = 'America/La_Paz';

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);

    // 1) obtener id_usuario
    final id = await ServicioCalendario.obtenerUsuarioIdPorCorreo(widget.correo);
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el usuario.')),
      );
      setState(() => _cargando = false);
      return;
    }

    _idUsuario = id;

    // 2) listar calendarios
    final lista = await ServicioCalendario.listarCalendariosDeUsuario(id);
    setState(() {
      _calendarios = lista;
      _cargando = false;
    });
  }

  Future<void> _crearCalendario() async {
    _nombreCtl.clear();
    _zonaHoraria = 'America/La_Paz';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('➕ Nuevo calendario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreCtl,
              decoration: const InputDecoration(labelText: 'Nombre del calendario'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _zonaHoraria,
              items: const [
                DropdownMenuItem(value: 'America/La_Paz', child: Text('America/La_Paz')),
                DropdownMenuItem(value: 'America/Lima', child: Text('America/Lima')),
                DropdownMenuItem(value: 'America/Bogota', child: Text('America/Bogota')),
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
              ],
              onChanged: (v) => setState(() => _zonaHoraria = v ?? 'America/La_Paz'),
              decoration: const InputDecoration(labelText: 'Zona horaria'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_nombreCtl.text.trim().isEmpty || _idUsuario == null) return;
              final error = await ServicioCalendario.crearCalendario(
                idUsuario: _idUsuario!,
                nombre: _nombreCtl.text.trim(),
                zonaHoraria: _zonaHoraria,
              );
              if (!mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              } else {
                Navigator.pop(context);
                await _cargarTodo();
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCalendario(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar calendario'),
        content: const Text('¿Seguro que deseas eliminar este calendario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (conf != true) return;

    final error = await ServicioCalendario.eliminarCalendario(id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calendario eliminado')));
      await _cargarTodo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _crearCalendario,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _calendarios.isEmpty
              ? const Center(child: Text('Aún no tienes calendarios. Creá el primero 👉'))
              : ListView.separated(
                  itemCount: _calendarios.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final cal = _calendarios[i];
                    return ListTile(
                      leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                      title: Text(cal['nombre'] ?? 'Sin nombre'),
                      subtitle: Text('Zona horaria: ${cal['zona_horaria'] ?? '-'}'),
                      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PantallaEventosCalendario(
        idCalendario: cal['id'],
        nombreCalendario: cal['nombre'],
      ),
    ),
  );
},
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarCalendario(cal['id'] as int),
                      ),
                    );
                  },
                ),
    );
  }
}
