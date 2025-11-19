//pantallas/autenticacion/pantalla_verificacion_pendiente.dart
import 'package:flutter/material.dart';
import '../../servicios/autenticacion/registro_verificacion_service.dart';

class PantallaVerificacionPendiente extends StatefulWidget {
  final String correo;
  const PantallaVerificacionPendiente({super.key, required this.correo});

  @override
  State<PantallaVerificacionPendiente> createState() =>
      _PantallaVerificacionPendienteState();
}

class _PantallaVerificacionPendienteState
    extends State<PantallaVerificacionPendiente> {
  bool _loading = false;
  String? _msg;

  Future<void> _reenviar() async {
    setState(() => _loading = true);
    final r = await RegistroVerificacionService.reenviarVerificacion(
      correo: widget.correo,
    );
    setState(() {
      _loading = false;
      _msg = r ?? 'Revisá tu correo';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg!)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificá tu correo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_unread,
                    size: 90, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Te enviamos un correo a ${widget.correo.replaceAll(RegExp(r'(?<=.).(?=[^@]*?@)'), '•')}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Abrí el enlace para activar tu cuenta.'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _reenviar,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reenviar verificación'),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                  child: const Text('Ya verifiqué, ir a Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
