//lib/rutas/rutas_app.dart
import 'package:flutter/material.dart';
import '../pantallas/inicio/pantalla_inicio.dart';
import '../pantallas/autenticacion/pantalla_login.dart';
import '../pantallas/principal/pantalla_principal.dart';
import '../pantallas/autenticacion/pantalla_recuperar.dart';
import '../pantallas/autenticacion/pantalla_nueva_contrasena.dart';
import '../pantallas/social/pantalla_usuarios.dart';
import '../pantallas/social/pantalla_solicitudes.dart';

Map<String, WidgetBuilder> obtenerRutas() {
  return {
    '/inicio': (_) => const PantallaInicio(),
    '/login': (_) => const PantallaLogin(),
    '/principal': (_) => const PantallaPrincipal(),
    '/recuperar': (_) => const PantallaRecuperar(),
    '/nueva_contrasena': (_) => const PantallaNuevaContrasena(),
    '/usuarios': (_) => const PantallaUsuarios(),
    '/solicitudes': (_) => const PantallaSolicitudes(),

  };
}

Route<dynamic>? generarRuta(RouteSettings settings) {
  return null;
}