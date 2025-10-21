import 'package:flutter/material.dart';
import 'pantallas/rutas/rutas_app.dart';
import 'servicios/supabase_service.dart';

class AplicacionCoCal extends StatelessWidget {
  const AplicacionCoCal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoCal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/inicio',
      routes: obtenerRutas(),
    );
  }
}
