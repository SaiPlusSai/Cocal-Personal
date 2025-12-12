// main.dart
import 'package:cocal_personal/proveedores/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'servicios/supabase_service.dart';
import 'servicios/notificacion_sistema_service.dart';
import 'rutas/rutas_app.dart';
import 'estilos/app_theme.dart';
import 'core/auth_gate.dart';
import 'pantallas/inicio/pantalla_inicio.dart';
import 'pantallas/principal/pantalla_principal.dart';
import 'pantallas/autenticacion/pantalla_login.dart';
import 'utils/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  await NotificacionSistemaService.inicializar();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const AplicacionCoCal(),
    ),
  );
}

class AplicacionCoCal extends StatelessWidget {
  const AplicacionCoCal({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Comprobar si hay un intent de navegación pendiente (desde notificación)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificacionSistemaService.ejecutarIntentPendiente();
    });

    return MaterialApp(
      title: 'CoCal',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      routes: obtenerRutas(),
      onGenerateRoute: generarRuta,
      // 👇 El árbol arranca en el AuthGate
      home: const AuthGate(
        loggedOut: PantallaLogin(), // en vez de PantallaInicio
        loggedIn: PantallaPrincipal(),
      ),
    );
  }
}
