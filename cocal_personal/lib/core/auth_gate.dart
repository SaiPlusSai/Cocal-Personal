//lib/core/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../servicios/autenticacion/perfil_service.dart';

class AuthGate extends StatefulWidget {
  final Widget loggedIn;
  final Widget loggedOut;
  const AuthGate({super.key, required this.loggedIn, required this.loggedOut});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final GoTrueClient _auth;

  @override
  void initState() {
    super.initState();
    _auth = Supabase.instance.client.auth;

    _auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (!mounted) return;

      // Cuando el usuario confirma email (magic link) o hace login
      if (event == AuthChangeEvent.signedIn) {
        // Upsert del perfil en tu tabla "users"
        await PerfilService.ensurePerfilDesdeAuth();
        setState(() {}); // Redibuja → muestra loggedIn
      }

      // Supabase crea una sesión temporal al abrir el link de recuperación
      if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(context).pushNamed('/nueva_contrasena');
      }

      if (event == AuthChangeEvent.signedOut) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _auth.currentSession;
    return session == null ? widget.loggedOut : widget.loggedIn;
  }
}
