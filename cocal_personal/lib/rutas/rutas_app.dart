//lib/rutas/rutas_app.dart
import 'package:flutter/material.dart';
import '../pantallas/inicio/pantalla_inicio.dart';
import '../pantallas/autenticacion/pantalla_login.dart';
import '../pantallas/principal/pantalla_principal.dart';
import '../pantallas/autenticacion/pantalla_recuperar.dart';
import '../pantallas/autenticacion/pantalla_nueva_contrasena.dart';
import '../pantallas/social/pantalla_usuarios.dart';
import '../pantallas/social/pantalla_solicitudes.dart';
import '../pantallas/perfil/pantalla_perfil.dart';
import '../pantallas/perfil/pantalla_configuracion.dart';
import '../pantallas/perfil/pantalla_editar_perfil.dart';

Map<String, WidgetBuilder> obtenerRutas() {
  return {
    '/inicio': (_) => const PantallaInicio(),
    '/login': (_) => const PantallaLogin(),
    '/principal': (_) => const PantallaPrincipal(),
    '/recuperar': (_) => const PantallaRecuperar(),
    '/nueva_contrasena': (_) => const PantallaNuevaContrasena(),
    '/usuarios': (_) => const PantallaUsuarios(),
    '/solicitudes': (_) => const PantallaSolicitudes(),
    '/perfil': (_) => const PantallaPerfil(),
    '/configuracion': (_) => const PantallaConfiguracion(),
    '/editar-perfil': (_) => const PantallaEditarPerfil(),

  };
}

Route<dynamic>? generarRuta(RouteSettings settings) {
  return null;
}