import 'package:flutter/material.dart';
import '../../servicios/autenticacion_service.dart';
import 'pantalla_registro.dart';
import '../principal/pantalla_principal.dart'; 

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

    // 🔹 Llamamos al servicio de autenticación
    final error = await AutenticacionService.iniciarSesion(
      correo: _emailCtl.text.trim(),
      contrasena: _passCtl.text,
    );

    setState(() => _cargando = false);

    // 🔸 Mostrar error si algo falla
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // ✅ Redirigir al dashboard con el correo del usuario
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PantallaPrincipal(correo: _emailCtl.text.trim()),
      ),
    );
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
            const Text(
              'Bienvenido a CoCal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 📧 Campo de correo
            TextField(
              controller: _emailCtl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),

            // 🔑 Campo de contraseña
            TextField(
              controller: _passCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 20),

            // 🔘 Botón de ingreso
            ElevatedButton(
              onPressed: _cargando ? null : _login,
              child: _cargando
                  ? const CircularProgressIndicator()
                  : const Text('Ingresar'),
            ),

            // 🔗 Enlace a registro
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaRegistro()),
              ),
              child: const Text('¿No tenés cuenta? Registrate'),
            ),
          ],
        ),
      ),
    );
  }
}
