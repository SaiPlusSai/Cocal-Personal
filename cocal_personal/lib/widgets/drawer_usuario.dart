// lib/widgets/drawer_usuario.dart
import 'package:flutter/material.dart';
import '../servicios/autenticacion/autenticacion_service.dart';

class DrawerUsuario extends StatelessWidget {
  final String nombre;
  final String apellido;
  final String correo;
  final String? fotoUrl; // 👈 nuevo

  const DrawerUsuario({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.fotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final tieneFoto = fotoUrl != null && fotoUrl!.isNotEmpty;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.indigo,
            ),
            accountName: Text('$nombre $apellido'),
            accountEmail: Text(correo),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: tieneFoto
                  ? NetworkImage(
                '$fotoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
              )
                  : null,
              child: !tieneFoto
                  ? const Icon(Icons.person, size: 40, color: Colors.indigo)
                  : null,
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi perfil'),
            onTap: () {
              Navigator.pushNamed(context, '/perfil');
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pushNamed(context, '/configuracion');
            },
          ),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await AutenticacionService.cerrarSesion();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
