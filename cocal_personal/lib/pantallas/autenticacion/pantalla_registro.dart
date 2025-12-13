// pantallas/autenticacion/pantalla_registro.dart

import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';
import 'pantalla_verificacion_pendiente.dart';
import 'pantalla_login.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtl = TextEditingController();
  final _apellidoCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();

  bool _cargando = false;
  bool _obscurePassword = true;

  // Colores Figma (idénticos al login)
  static const Color colorFondoClaro = Color(0xFFC3E5DF);
  static const Color colorFondoOscuro = Color(0xFF6BC9B7);
  static const Color colorBoton = Color(0xFF6BC9B7);
  static const Color colorTextoOscuro = Color(0xFF1A3A34);
  static const Color colorHoja = Color(0xFF5DB075);

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final error = await AutenticacionService.registrar(
      correo: _emailCtl.text.trim(),
      contrasena: _passCtl.text.trim(),
      nombre: _nombreCtl.text.trim(),
      apellido: _apellidoCtl.text.trim(),
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PantallaVerificacionPendiente(correo: _emailCtl.text.trim()),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: colorTextoOscuro, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: colorTextoOscuro.withOpacity(0.4),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: colorTextoOscuro.withOpacity(0.6),
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: colorTextoOscuro.withOpacity(0.6),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [colorFondoClaro, colorFondoOscuro],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // LOGO
                      Hero(
                        tag: 'logo_cocal',
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colorHoja,
                                borderRadius: BorderRadius.circular(40),
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
                                color: colorTextoOscuro,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'CALENDARIO COLABORATIVO',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorTextoOscuro,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // TÍTULO
                      const Text(
                        'Regístrate a CoCal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorTextoOscuro,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // CAMPOS
                      _inputField(
                        hint: 'Nombre',
                        icon: Icons.person_outline,
                        controller: _nombreCtl,
                        validator: (v) =>
                            v!.isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        hint: 'Apellido',
                        icon: Icons.person_outline,
                        controller: _apellidoCtl,
                        validator: (v) =>
                            v!.isEmpty ? 'Ingresa tu apellido' : null,
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        hint: 'username@gmail.com',
                        icon: Icons.email_outlined,
                        controller: _emailCtl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _inputField(
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        controller: _passCtl,
                        isPassword: true,
                        validator: (v) {
                          if (v!.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // BOTÓN REGISTRARSE
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
                          onPressed: _cargando ? null : _registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorBoton,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: colorBoton.withOpacity(
                              0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _cargando
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // VOLVER A LOGIN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes una cuenta?  ',
                            style: TextStyle(
                              color: colorTextoOscuro.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PantallaLogin(),
                              ),
                            ),
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
