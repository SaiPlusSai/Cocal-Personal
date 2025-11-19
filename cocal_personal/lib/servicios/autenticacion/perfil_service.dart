import '../supabase_service.dart';

class PerfilService {
  static final _db = SupabaseService.cliente;
  static final _auth = SupabaseService.cliente.auth;

  static Future<void> ensurePerfilDesdeAuth() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final email = user.email;
    final meta = user.userMetadata ?? {};
    final nombre = (meta['nombre'] ?? '').toString();
    final apellido = (meta['apellido'] ?? '').toString();

    await _db.from('users').upsert({
      'id': user.id,        // uuid (pk) = auth.uid()
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
    });
  }
}
