import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'configuracion/cliente_supabase.dart';
import 'configuracion/tema_principal.dart';
import 'pantallas/autenticacion/pantalla_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const AplicacionCoCal());
}

class AplicacionCoCal extends StatelessWidget {
  const AplicacionCoCal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoCal - Calendario Colaborativo',
      debugShowCheckedModeBanner: false,
      theme: temaPrincipal,
      home: const PantallaLogin(),
    );
  }
}
