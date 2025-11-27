//lib/pantallas/perfil/pantalla_perfil.dart
import 'package:flutter/material.dart';
import '../../servicios/supabase_service.dart';

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


  @override
  void initState() {
    super.initState();
    _cargarPerfil();
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
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
              onPressed: () {
                Navigator.pushNamed(context, '/editar-perfil');
                _cargarPerfil();
              },
            )
          ],
        ),
      ),
    );
  }
}
