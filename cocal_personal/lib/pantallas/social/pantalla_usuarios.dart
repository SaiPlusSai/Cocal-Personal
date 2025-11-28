// lib/pantallas/social/pantalla_usuarios.dart
import 'package:flutter/material.dart';
import '../../servicios/social/amigos_service.dart';
import '../../servicios/social/modelos_amigos.dart';
import 'pantalla_perfil_usuario.dart';

class PantallaUsuarios extends StatefulWidget {
  const PantallaUsuarios({super.key});

  @override
  State<PantallaUsuarios> createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends State<PantallaUsuarios> {
  final _busquedaCtl = TextEditingController();
  bool _cargando = false;
  List<UsuarioResumen> _resultados = [];
  Map<int, bool> _sonAmigosCache = {}; // Cachear estado de amistad

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

    // Cargar estado de amistad para cada resultado
    final cache = <int, bool>{};
    for (final usuario in res) {
      cache[usuario.id] = await AmigosService.sonAmigos(usuario.id);
    }

    setState(() {
      _resultados = res;
      _sonAmigosCache = cache;
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

    // Actualizar el estado de amistad
    setState(() {
      _sonAmigosCache[u.id] = false; // La solicitud está pendiente, no son amigos aún
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                  final sonAmigos = _sonAmigosCache[u.id] ?? false;

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('${u.nombre} ${u.apellido}'),
                      subtitle: Text(u.correo),
                      trailing: sonAmigos
                          ? IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          color: scheme.primary,
                        ),
                        onPressed: null, // Deshabilitado porque ya son amigos
                      )
                          : IconButton(
                        icon: Icon(Icons.person_add, color: scheme.primary),
                        onPressed: () => _enviarSolicitud(u),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PantallaPerfilUsuario(userId: u.id),
                          ),
                        );
                      },
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
