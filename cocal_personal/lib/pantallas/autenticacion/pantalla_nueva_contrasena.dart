// pantallas/autenticacion/pantalla_nueva_contrasena.dart
import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';

class PantallaNuevaContrasena extends StatefulWidget {
  const PantallaNuevaContrasena({super.key});

  @override
  State<PantallaNuevaContrasena> createState() =>
      _PantallaNuevaContrasenaState();
}

class _PantallaNuevaContrasenaState extends State<PantallaNuevaContrasena> {
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _oculto1 = true;
  bool _oculto2 = true;
  bool _loading = false;

  // Colores del diseño CoCal
  static const Color colorFondoClaro = Color(0xFFC3E5DF);
  static const Color colorFondoOscuro = Color(0xFF6BC9B7);
  static const Color colorBoton = Color(0xFF6BC9B7);
  static const Color colorTextoOscuro = Color(0xFF1A3A34);
  static const Color colorHoja = Color(0xFF5DB075);

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pol)));
      return;
    }

    setState(() => _loading = true);
    final err = await AutenticacionService.actualizarPassword(p1);
    setState(() => _loading = false);

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada. Iniciá sesión.')),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
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
                      'Nueva contraseña',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorTextoOscuro,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Campo de nueva contraseña
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _pass1,
                        obscureText: _oculto1,
                        decoration: InputDecoration(
                          hintText: 'Nueva contraseña',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorTextoOscuro.withOpacity(0.6),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _oculto1
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colorTextoOscuro.withOpacity(0.6),
                            ),
                            onPressed: () => setState(() => _oculto1 = !_oculto1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo de repetir contraseña
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _pass2,
                        obscureText: _oculto2,
                        decoration: InputDecoration(
                          hintText: 'Repetir contraseña',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorTextoOscuro.withOpacity(0.6),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _oculto2
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colorTextoOscuro.withOpacity(0.6),
                            ),
                            onPressed: () => setState(() => _oculto2 = !_oculto2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                        ),
                        onSubmitted: (_) => _loading ? null : _guardar(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Requisitos: 8+ caracteres, 1 mayúscula, 1 minúscula, 1 número.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorTextoOscuro,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón guardar
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
                        onPressed: _loading ? null : _guardar,
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
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
