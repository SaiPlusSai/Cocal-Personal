// lib/pantallas/social/pantalla_usuarios.dart
import 'package:flutter/material.dart';
import '../../servicios/social/amigos_service.dart';

class PantallaUsuarios extends StatefulWidget {
  const PantallaUsuarios({super.key});

  @override
  State<PantallaUsuarios> createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends State<PantallaUsuarios> {
  final _busquedaCtl = TextEditingController();
  bool _cargando = false;
  List<UsuarioResumen> _resultados = [];

  @override
  void dispose() {
    _busquedaCtl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final q = _busquedaCtl.text.trim();
    if (q.isEmpty) return;

    setState(() => _cargando = true);
    final res = await AmigosService.buscarUsuarios(q);
    if (!mounted) return;
    setState(() {
      _resultados = res;
      _cargando = false;
    });
  }

  Future<void> _enviarSolicitud(UsuarioResumen u) async {
    final error = await AmigosService.enviarSolicitud(idDestinatario: u.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Solicitud enviada a ${u.nombre}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _busquedaCtl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Buscar usuarios',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busquedaCtl.clear();
                    setState(() => _resultados = []);
                  },
                ),
              ),
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _buscar,
                icon: _cargando
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _resultados.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.builder(
                itemCount: _resultados.length,
                itemBuilder: (_, i) {
                  final u = _resultados[i];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('${u.nombre} ${u.apellido}'),
                      subtitle: Text(u.correo),
                      trailing: IconButton(
                        icon: Icon(Icons.person_add, color: scheme.primary),
                        onPressed: () => _enviarSolicitud(u),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
