import 'package:flutter/material.dart';
import '../../servicios/autenticacion_service.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _nombreCtl = TextEditingController();
  final _apellidoCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _cargando = false;

  Future<void> _registrar() async {
    setState(() => _cargando = true);

    final error = await AutenticacionService.registrar(
  correo: _emailCtl.text.trim(),
  contrasena: _passCtl.text,
  nombre: _nombreCtl.text.trim(),
  apellido: _apellidoCtl.text.trim(),
);


    setState(() => _cargando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta creada correctamente. Revisá tu correo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de usuario')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Hero(
              tag: 'logo_cocal',
              child: Icon(
                Icons.calendar_month,
                size: 100,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreCtl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apellidoCtl,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargando ? null : _registrar,
              child: _cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
