import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../proveedores/proveedor_autenticacion.dart';
import '../dashboard/pantalla_dashboard.dart';
import 'pantalla_registro.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final correoCtrl = TextEditingController();
  final contrasenaCtrl = TextEditingController();
  bool cargando = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<ProveedorAutenticacion>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (v) => v!.isEmpty ? 'Ingrese su correo' : null,
              ),
              TextFormField(
                controller: contrasenaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) => v!.isEmpty ? 'Ingrese su contraseña' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: cargando
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => cargando = true);
                          final error = await auth.iniciarSesion(
                            correoCtrl.text.trim(),
                            contrasenaCtrl.text.trim(),
                          );
                          setState(() => cargando = false);
                          if (error == null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PantallaDashboard()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        }
                      },
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text('Entrar'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaRegistro()),
                ),
                child: const Text('¿No tienes cuenta? Regístrate'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
