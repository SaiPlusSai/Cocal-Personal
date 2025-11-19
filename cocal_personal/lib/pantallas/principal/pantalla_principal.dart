//lib/principal/pantalla_principal.dart
import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await AutenticacionService.cerrarSesion();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal de CoCal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              '🎯 Bienvenido a tu panel principal de CoCal',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Acá vas a poder crear eventos, grupos y foros colaborativos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
