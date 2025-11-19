import 'package:flutter/material.dart';
import 'servicios/supabase_service.dart';
import 'rutas/rutas_app.dart';
import 'estilos/app_theme.dart';

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
      theme: AppTheme.light(),
      routes: obtenerRutas(),
      onGenerateRoute: generarRuta,    // 👈 rutas dinámicas
      initialRoute: '/inicio',         // 👈 ruta inicial
    );
  }
}
