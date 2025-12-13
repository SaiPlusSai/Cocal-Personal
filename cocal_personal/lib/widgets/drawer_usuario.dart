// lib/widgets/drawer_usuario.dart
import 'package:flutter/material.dart';
import '../servicios/autenticacion/autenticacion_service.dart';

class DrawerUsuario extends StatelessWidget {
  final String nombre;
  final String apellido;
  final String correo;
  final String? fotoUrl;

  // Colores opcionales para diseño coherente
  final Color colorFondo;
  final Color colorTexto;
  final Color colorAvatar;

  const DrawerUsuario({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.fotoUrl,
    this.colorFondo = const Color(0xFF6BC9B7),
    this.colorTexto = const Color(0xFF1A3A34),
    this.colorAvatar = const Color(0xFF5DB075),
  });

  @override
  Widget build(BuildContext context) {
    final tieneFoto = fotoUrl != null && fotoUrl!.isNotEmpty;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorFondo.withOpacity(0.8), colorFondo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              '$nombre $apellido',
              style: TextStyle(color: colorTexto, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              correo,
              style: TextStyle(color: colorTexto.withOpacity(0.8)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: tieneFoto
                  ? NetworkImage(
                      '$fotoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                    )
                  : null,
              child: !tieneFoto
                  ? Icon(Icons.person, size: 40, color: colorAvatar)
                  : null,
            ),
          ),

          ListTile(
            leading: Icon(Icons.person, color: colorTexto),
            title: Text('Mi perfil', style: TextStyle(color: colorTexto)),
            onTap: () {
              Navigator.pushNamed(context, '/perfil');
            },
          ),

          ListTile(
            leading: Icon(Icons.settings, color: colorTexto),
            title: Text('Configuración', style: TextStyle(color: colorTexto)),
            onTap: () {
              Navigator.pushNamed(context, '/configuracion');
            },
          ),

          const Spacer(),

          ListTile(
            leading: Icon(Icons.logout, color: colorTexto),
            title: Text('Cerrar sesión', style: TextStyle(color: colorTexto)),
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
