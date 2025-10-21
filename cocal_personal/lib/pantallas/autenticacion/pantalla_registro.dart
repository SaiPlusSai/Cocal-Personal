import 'package:flutter/material.dart';
import '../../servicios/servicio_autenticacion.dart';

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
    final error = await ServicioAutenticacion.registrar(
      email: _emailCtl.text.trim(),
      password: _passCtl.text,
      nombre: _nombreCtl.text.trim(),
      apellido: _apellidoCtl.text.trim(),
    );
    setState(() => _cargando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // volver al login
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada. Revisa tu correo.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _nombreCtl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 8),
            TextField(controller: _apellidoCtl, decoration: const InputDecoration(labelText: 'Apellido')),
            const SizedBox(height: 8),
            TextField(controller: _emailCtl, decoration: const InputDecoration(labelText: 'Correo')),
            const SizedBox(height: 8),
            TextField(controller: _passCtl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargando ? null : _registrar,
              child: _cargando ? const CircularProgressIndicator() : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
