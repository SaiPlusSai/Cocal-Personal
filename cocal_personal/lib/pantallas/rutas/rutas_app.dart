import 'package:flutter/material.dart';
import '../inicio/pantalla_inicio.dart';
import '../autenticacion/pantalla_login.dart';
import '../principal/pantalla_principal.dart';

Map<String, WidgetBuilder> obtenerRutas() {
  return {
    '/inicio': (context) => const PantallaInicio(),
    '/login': (context) => const PantallaLogin(),
    '/principal': (context) => const PantallaPrincipal(),
  };
}
