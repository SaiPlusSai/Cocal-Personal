import 'package:flutter/material.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  bool notificaciones = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: notificaciones,
            title: const Text('Notificaciones'),
            onChanged: (v) {
              setState(() => notificaciones = v);
            },
          ),
          ListTile(
            title: const Text('Tema'),
            trailing: DropdownButton<String>(
              items: const [
                DropdownMenuItem(value: 'oscuro', child: Text('Oscuro')),
                DropdownMenuItem(value: 'claro', child: Text('Claro')),
              ],
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}
