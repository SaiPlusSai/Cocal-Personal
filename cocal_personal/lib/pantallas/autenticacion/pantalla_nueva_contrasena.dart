//pantallas/autenticacion/pantallla_nueva_contrasena.dart
import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';

class PantallaNuevaContrasena extends StatefulWidget {
  const PantallaNuevaContrasena({super.key});

  @override
  State<PantallaNuevaContrasena> createState() => _PantallaNuevaContrasenaState();
}

class _PantallaNuevaContrasenaState extends State<PantallaNuevaContrasena> {
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _oculto1 = true;
  bool _oculto2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  String? _validarPolitica(String pass) {
    if (pass.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(pass)) return 'Incluí al menos una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(pass)) return 'Incluí al menos una minúscula';
    if (!RegExp(r'\d').hasMatch(pass)) return 'Incluí al menos un número';
    return null;
  }

  Future<void> _guardar() async {
    final p1 = _pass1.text;
    final p2 = _pass2.text;

    if (p1 != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    final pol = _validarPolitica(p1);
    if (pol != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pol)));
      return;
    }

    setState(() => _loading = true);
    final err = await AutenticacionService.actualizarPassword(p1);
    setState(() => _loading = false);

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada. Iniciá sesión.')),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _pass1,
                  obscureText: _oculto1,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _oculto1 = !_oculto1),
                      icon: Icon(_oculto1 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass2,
                  obscureText: _oculto2,
                  decoration: InputDecoration(
                    labelText: 'Repetir contraseña',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _oculto2 = !_oculto2),
                      icon: Icon(_oculto2 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  onSubmitted: (_) => _loading ? null : _guardar(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Requisitos: 8+ caracteres, 1 mayúscula, 1 minúscula, 1 número.',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: t.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _guardar,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
