import 'package:cocal_personal/pantallas/inicio/pantalla_inicio.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'servicios/supabase_service.dart';

import 'estilos/app_theme.dart';
import 'pantallas/inicio/pantalla_inicio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  runApp(const AplicacionCoCal());
}

class AplicacionCoCal extends StatelessWidget {
  const AplicacionCoCal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoCal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(), // 👈 aquí jalamos el tema
      home: const PantallaInicio(), // o tu router inicial
    );
  }
}
