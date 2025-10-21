import 'package:flutter/material.dart';

class PantallaLogin extends StatelessWidget {
  const PantallaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de sesión')),
      body: const Center(
        child: Text('Bienvenido a CoCal 🎉', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
