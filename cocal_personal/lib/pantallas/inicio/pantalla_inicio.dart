//lib/pantallas/inicio/pantalla_inicio.dart
import 'package:flutter/material.dart';
import '../autenticacion/pantalla_login.dart';
import '../autenticacion/pantalla_registro.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/ícono con color de la marca
                  Hero(
                    tag: 'logo_cocal',
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 110,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Título con tipografía del tema
                  Text(
                    'Bienvenido a CoCal 🎉',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: 10),

                  // Descripción usando onBackground con opacidad
                  Text(
                    'Tu calendario colaborativo moderno y seguro.\nOrganizá, compartí y conectá con tu equipo.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onBackground.withOpacity(0.70),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Botón primario (usa ElevatedButtonTheme del AppTheme)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PantallaLogin()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Botón secundario/alternativo con el color "secondary" de tu paleta
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.secondary,
                        side: BorderSide(color: scheme.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Crear una cuenta nueva'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PantallaRegistro()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Pie de página con color sutil
                  Text(
                    'Versión 1.0.0 • CoCal- CAMBIADO',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onBackground.withOpacity(0.40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
