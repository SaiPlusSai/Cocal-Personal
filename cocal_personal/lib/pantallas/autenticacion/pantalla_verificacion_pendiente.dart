// pantallas/autenticacion/pantalla_verificacion_pendiente.dart
import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';

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

  // Colores del diseño CoCal
  static const Color colorFondoClaro = Color(0xFFC3E5DF);
  static const Color colorFondoOscuro = Color(0xFF6BC9B7);
  static const Color colorBoton = Color(0xFF6BC9B7);
  static const Color colorTextoOscuro = Color(0xFF1A3A34);
  static const Color colorHoja = Color(0xFF5DB075);

  Future<void> _reenviar() async {
    setState(() => _loading = true);

    final error = await AutenticacionService.reenviarVerificacion(
      widget.correo,
    );

    setState(() => _loading = false);
    if (!mounted) return;

    final msg = (error == null)
        ? 'Te enviamos nuevamente el enlace de verificación.'
        : 'No se pudo reenviar el correo: $error';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error == null
            ? Colors.green.shade400
            : Colors.red.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorFondoClaro, colorFondoOscuro],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Hero(
                      tag: 'logo_cocal',
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorHoja,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(40),
                                topRight: Radius.circular(40),
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'CoCal',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: colorTextoOscuro,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'CALENDARIO COLABORATIVO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorTextoOscuro,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    const Text(
                      'Verificación pendiente',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorTextoOscuro,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Te enviamos un correo a ${widget.correo.replaceAll(RegExp(r'(?<=.).(?=[^@]*?@)'), '•')}\nAbrí el enlace para activar tu cuenta.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: colorTextoOscuro,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botón reenviar
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorBoton.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _reenviar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorBoton,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: colorBoton.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Reenviar verificación',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (_) => false,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: colorTextoOscuro,
                      ),
                      child: const Text(
                        'Ya verifiqué, ir a Iniciar sesión',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
