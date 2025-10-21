import 'package:flutter/material.dart';
import '../autenticacion/pantalla_login.dart';
import '../autenticacion/pantalla_registro.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Hero(
                  tag: 'logo_cocal',
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 110,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Bienvenido a CoCal 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu calendario colaborativo moderno y seguro.\nOrganizá, compartí y conectá con tu equipo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar sesión'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PantallaLogin()),
                    );
                  },
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.indigo),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text(
                    'Crear una cuenta nueva',
                    style: TextStyle(color: Colors.indigo),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PantallaRegistro()),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Text(
                  'Versión 1.0.0 • CoCal',
                  style: TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
