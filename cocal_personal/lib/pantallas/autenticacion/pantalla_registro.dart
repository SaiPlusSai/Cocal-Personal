//pantallas/autenticacion/pantalla_registro.dart
import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';
import 'pantalla_verificacion_pendiente.dart';

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

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaVerificacionPendiente(
          correo: _emailCtl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de usuario')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Hero(
              tag: 'logo_cocal',
              child: Icon(Icons.calendar_month, size: 100, color: scheme.primary),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nombreCtl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _apellidoCtl,
              decoration: const InputDecoration(labelText: 'Apellido'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _passCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              onSubmitted: (_) => _cargando ? null : _registrar(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _registrar,
                child: _cargando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
