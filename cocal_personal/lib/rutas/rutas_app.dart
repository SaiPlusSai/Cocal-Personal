import 'package:flutter/material.dart';
import '../pantallas/inicio/pantalla_inicio.dart';
import '../pantallas/autenticacion/pantalla_login.dart';

/// 🔹 Mapa global de rutas de navegación de CoCal
/// 
/// Notá que NO se incluye `PantallaPrincipal` aquí,
/// porque requiere un parámetro (correo) que solo se obtiene
/// al iniciar sesión correctamente.
Map<String, WidgetBuilder> obtenerRutas() {
  return {
    '/inicio': (context) => const PantallaInicio(),
    '/login': (context) => const PantallaLogin(),
  };
}
