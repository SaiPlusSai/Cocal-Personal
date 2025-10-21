import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../servicios/servicio_autenticacion.dart';

/// Provider que maneja la sesión del usuario actual
class ProveedorAutenticacion with ChangeNotifier {
  final _cliente = Supabase.instance.client;
  final _almacen = const FlutterSecureStorage();

  bool _autenticado = false;
  bool get autenticado => _autenticado;

  String? _correoUsuario;
  String? get correoUsuario => _correoUsuario;

  ProveedorAutenticacion() {
    _verificarSesionInicial();
  }

  /// Verifica si hay una sesión activa al iniciar la app
  Future<void> _verificarSesionInicial() async {
    try {
      final session = _cliente.auth.currentSession;
      if (session != null) {
        _autenticado = true;
        _correoUsuario = session.user.email;
        await _almacen.write(key: 'token', value: session.accessToken);
      } else {
        final tokenGuardado = await _almacen.read(key: 'token');
        if (tokenGuardado != null) {
          _autenticado = true;
        }
      }
    } catch (_) {
      _autenticado = false;
    }
    notifyListeners();
  }

  /// Iniciar sesión
  Future<String?> iniciarSesion(String email, String password) async {
    final error = await ServicioAutenticacion.iniciarSesion(
      email: email,
      password: password,
    );
    if (error == null) {
      _autenticado = true;
      _correoUsuario = email;
      final session = _cliente.auth.currentSession;
      await _almacen.write(key: 'token', value: session?.accessToken);
    }
    notifyListeners();
    return error;
  }

  /// Registrar usuario
  Future<String?> registrar(
      String nombre, String apellido, String email, String password) async {
    final error = await ServicioAutenticacion.registrar(
      email: email,
      password: password,
      nombre: nombre,
      apellido: apellido,
    );
    if (error == null) {
      _autenticado = true;
      _correoUsuario = email;
    }
    notifyListeners();
    return error;
  }

  /// Cerrar sesión
  Future<void> cerrarSesion() async {
    await ServicioAutenticacion.cerrarSesion();
    await _almacen.delete(key: 'token');
    _autenticado = false;
    _correoUsuario = null;
    notifyListeners();
  }
}
