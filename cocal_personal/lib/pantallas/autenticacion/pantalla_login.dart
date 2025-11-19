//pantallas/autenticacion/pantalla_login.dart
import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';
import 'pantalla_registro.dart';
import 'pantalla_recuperar.dart';

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

    final error = await AutenticacionService.iniciarSesion(
      correo: _emailCtl.text.trim(),
      contrasena: _passCtl.text,
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
    // 👇 ya no navegamos, el AuthGate se encarga
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso a CoCal')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo_cocal',
                  child: Icon(Icons.calendar_month, size: 100, color: scheme.primary),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _passCtl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  onSubmitted: (_) => _cargando ? null : _login(),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaRecuperar()),
                      );
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _login,
                    child: _cargando
                        ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Ingresar'),
                  ),
                ),
                const SizedBox(height: 8),

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
        ),
      ),
    );
  }
}
