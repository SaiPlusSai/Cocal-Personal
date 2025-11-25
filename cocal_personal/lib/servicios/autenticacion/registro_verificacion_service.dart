//lib/servicios/autenticacion/registro_verificacion_service.dart
/// Auth validators
class RegistroVerificacionService {
  // ===== Helpers =====
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
}
