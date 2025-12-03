//lib/pantallas/perfil/pantalla_perfil.dart
import 'package:flutter/material.dart';
import '../../servicios/supabase_service.dart';
import '../../servicios/social/amigos_service.dart';
import '../../servicios/social/modelos_amigos.dart';
import '../../servicios/temas_interes_service.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  String nombre = '';
  String apellido = '';
  String correo = '';
  bool cargando = true;
  String? fotoUrl;
  List<UsuarioResumen> _amigos = [];
  bool _cargandoAmigos = true;
  List<TemaInteres> _temas = [];
  bool _cargandoTemas = true;


  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _cargarAmigos();
    _cargarTemas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cada vez que la pantalla vuelve a estar visible
    _cargarTemas();
  }

  Future<void> _cargarTemas() async {
    setState(() {
      _cargandoTemas = true;
    });
    try {
      final temas = await TemasInteresService.obtenerTemasActual();
      setState(() {
        _temas = temas;
      });
    } catch (e) {
      debugPrint('[PERFIL] Error cargando temas: $e');
    } finally {
      setState(() {
        _cargandoTemas = false;
      });
    }
  }

  Future<void> _cargarAmigos() async {
    setState(() {
      _cargandoAmigos = true;
    });
    try {
      final lista = await AmigosService.obtenerAmigos();
      setState(() {
        _amigos = lista;
      });
    } catch (e) {
      debugPrint('[PERFIL] Error cargando amigos: $e');
    } finally {
      setState(() {
        _cargandoAmigos = false;
      });
    }
  }

  Future<void> _cargarPerfil() async {
    final cliente = SupabaseService.cliente;
    final user = cliente.auth.currentUser;

    if (user == null) return;

    final res = await cliente
        .from('usuario')
        .select()
        .eq('correo', user.email!)
        .single();

    setState(() {
      nombre = res['nombre'];
      apellido = res['apellido'] ?? '';
      correo = res['correo'];
      cargando = false;
      fotoUrl = res['foto_url'];

    });
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: fotoUrl != null
                  ? NetworkImage('$fotoUrl?v=${DateTime.now().millisecondsSinceEpoch}')
                  : null,
              child: fotoUrl == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),
            Text('$nombre $apellido',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(correo),
            const SizedBox(height: 20),

            // Temas de interés
            const Text('Mis temas de interés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _cargandoTemas
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                : _temas.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No has añadido temas de interés'),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _temas.map((tema) {
                          return Chip(
                            label: Text(tema.nombre),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 20),

            // Amigos section
            const Text('Mis amigos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: _cargandoAmigos
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _amigos.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No tienes amigos aún')),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _amigos.length,
                          itemBuilder: (context, i) {
                            final a = _amigos[i];
                            return ListTile(
                              leading: CircleAvatar(child: Text(a.nombre.isNotEmpty ? a.nombre[0] : '?')),
                              title: Text(a.nombreCompleto),
                              subtitle: Text(a.correo),
                              onTap: () {
                                // Opcional: navegar al perfil del amigo
                                Navigator.pushNamed(context, '/perfil-usuario', arguments: {'userId': a.id});
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(height: 1),
                        ),
            ),

            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
              onPressed: () async {
                await Navigator.pushNamed(context, '/editar-perfil');
                // Recargar después de volver de editar
                _cargarPerfil();
                _cargarTemas();
                _cargarAmigos();
              },
            )
          ],
        ),
      ),
    );
  }
}
