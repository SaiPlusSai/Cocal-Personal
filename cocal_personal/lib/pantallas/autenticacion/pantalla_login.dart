import 'package:flutter/material.dart';
import '../../servicios/servicio_autenticacion.dart';
import 'pantalla_registro.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _cargando = false;

  Future<void> _login() async {
    setState(() => _cargando = true);
    final error = await ServicioAutenticacion.iniciarSesion(
      email: _emailCtl.text.trim(),
      password: _passCtl.text,
    );
    setState(() => _cargando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Al iniciar sesión correctamente, navegar a pantalla principal
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/principal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso a CoCal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenido a CoCal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargando ? null : _login,
              child: _cargando ? const CircularProgressIndicator() : const Text('Ingresar'),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRegistro())),
              child: const Text('¿No tenés cuenta? Registrate'),
            ),
          ],
        ),
      ),
    );
  }
}
