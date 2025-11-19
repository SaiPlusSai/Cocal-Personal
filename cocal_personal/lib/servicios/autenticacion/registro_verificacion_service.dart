//lib/servicios/autenticacion/registro_verificacion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../supabase_service.dart';

/// Registro + verificación de email (enviar, reenviar, confirmar)
class RegistroVerificacionService {
  static final _cliente = SupabaseService.cliente;

  // ===== Helpers =====
  static String _hash(String plain) =>
      sha256.convert(utf8.encode(plain)).toString();

  static String _tokenSeguro([int bytes = 32]) {
    final rnd = Random.secure();
    final list = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return base64Url.encode(list).replaceAll('=', '');
  }

  static bool validarEmail(String correo) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(correo);
  }

  static String? validarPassword(String pass) {
    if (pass.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(pass)) return 'Incluí al menos una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(pass)) return 'Incluí al menos una minúscula';
    if (!RegExp(r'\d').hasMatch(pass)) return 'Incluí al menos un número';
    return null;
  }

  // ===== Registro con verificación por email =====
  /// Crea el usuario con `verificado=false`, genera token, guarda expiración (24h)
  /// e invoca la Edge Function `enviar-verificacion`.
  static Future<String?> registrar({
    required String correo,
    required String contrasena,
    required String nombre,
    String? apellido,
  }) async {
    try {
      if (!validarEmail(correo)) return 'Correo inválido';
      final errPol = validarPassword(contrasena);
      if (errPol != null) return errPol;

      final existente = await _cliente
          .from('usuario')
          .select('id')
          .eq('correo', correo)
          .maybeSingle();

      if (existente != null && existente.isNotEmpty) {
        return 'El correo ya está registrado. Iniciá sesión o recuperá tu cuenta.';
      }

      final token = _tokenSeguro();
      final expira = DateTime.now().toUtc().add(const Duration(hours: 24));

      await _cliente.from('usuario').insert({
        'correo': correo,
        'contrasena': _hash(contrasena),
        'nombre': nombre,
        'apellido': apellido ?? '',
        'verificado': false,
        'verif_token': token,
        'verif_expira': expira.toIso8601String(),
        'intentos_fallidos': 0,
        'bloqueado_hasta': null,
      });

      // Enviar correo de verificación (Edge Function)
      await _cliente.functions.invoke(
        'enviar-verificacion',
        body: {'correo': correo, 'token': token},
      );

      return null;
    } catch (e) {
      return 'Error al registrar: $e';
    }
  }

  /// Reenvía el enlace de verificación (genera nuevo token + 24h)
  static Future<String?> reenviarVerificacion({required String correo}) async {
    try {
      final user = await _cliente
          .from('usuario')
          .select('id, verificado')
          .eq('correo', correo)
          .maybeSingle();

      if (user == null) return 'Si el correo existe, te enviamos el enlace.';
      if (user['verificado'] == true) return 'Tu cuenta ya está verificada.';

      final token = _tokenSeguro();
      final expira = DateTime.now().toUtc().add(const Duration(hours: 24));

      await _cliente.from('usuario').update({
        'verif_token': token,
        'verif_expira': expira.toIso8601String(),
      }).eq('id', user['id']);

      await _cliente.functions.invoke(
        'enviar-verificacion',
        body: {'correo': correo, 'token': token},
      );

      return 'Te enviamos un nuevo enlace a tu correo.';
    } catch (e) {
      return 'No se pudo reenviar la verificación: $e';
    }
  }

  /// Confirma la verificación usando el token (desde el link del email)
  static Future<String?> confirmarVerificacion({required String token}) async {
    try {
      final user = await _cliente
          .from('usuario')
          .select('id, verif_expira, verificado')
          .eq('verif_token', token)
          .maybeSingle();

      if (user == null) return 'Enlace inválido o expirado.';
      if (user['verificado'] == true) return null;

      final expira = DateTime.parse(user['verif_expira'] as String);
      if (DateTime.now().toUtc().isAfter(expira)) {
        return 'El enlace de verificación ha expirado. Reenviá la verificación.';
      }

      await _cliente.from('usuario').update({
        'verificado': true,
        'verif_token': null,
        'verif_expira': null,
      }).eq('id', user['id']);

      return null;
    } catch (e) {
      return 'Error al verificar la cuenta: $e';
    }
  }
}
