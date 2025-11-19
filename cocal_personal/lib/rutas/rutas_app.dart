import 'package:flutter/material.dart';
import '../pantallas/inicio/pantalla_inicio.dart';
import '../pantallas/autenticacion/pantalla_login.dart';
import '../pantallas/principal/pantalla_principal.dart';
import '../pantallas/autenticacion/pantalla_recuperar.dart';
import '../pantallas/autenticacion/pantalla_nueva_contrasena.dart';

Map<String, WidgetBuilder> obtenerRutas() {
  return {
    '/inicio': (_) => const PantallaInicio(),
    '/login': (_) => const PantallaLogin(),
    '/principal': (_) => const PantallaPrincipal(),
    '/recuperar': (_) => const PantallaRecuperar(),
    '/nueva_contrasena': (_) => const PantallaNuevaContrasena(),
  };
}

Route<dynamic>? generarRuta(RouteSettings settings) {
  return null;
}
