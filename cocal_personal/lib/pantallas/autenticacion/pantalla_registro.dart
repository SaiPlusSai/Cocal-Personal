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

  /// Función que maneja el registro del usuario
  Future<void> _registrar() async {
    setState(() => _cargando = true);

    final error = await AutenticacionService.registrar(
      correo: _emailCtl.text.trim(),
      contrasena: _passCtl.text,
      nombre: _nombreCtl.text.trim(),
      apellido: _apellidoCtl.text.trim(),
    );

    setState(() => _cargando = false);

    // Mostrar error si algo falla
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (!mounted) return;

    // Volver al login al registrarse correctamente
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada exitosamente. Revisa tu correo 📧'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Crear una cuenta en CoCal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Nombre
            TextField(
              controller: _nombreCtl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),

            // Apellido
            TextField(
              controller: _apellidoCtl,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            const SizedBox(height: 8),

            // Correo electrónico
            TextField(
              controller: _emailCtl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 8),

            // Contraseña
            TextField(
              controller: _passCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 16),

            // Botón de registro
            ElevatedButton(
              onPressed: _cargando ? null : _registrar,
              child: _cargando
                  ? const CircularProgressIndicator()
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
