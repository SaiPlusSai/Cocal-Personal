// lib/core/auth_gate.dart
import 'dart:async';
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
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _auth = Supabase.instance.client.auth;

    _sub = _auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (!mounted) return;

      if (event == AuthChangeEvent.signedIn) {
        await PerfilService.ensurePerfilDesdeAuth();
        setState(() {});
      }

      if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(context).pushNamed('/nueva_contrasena');
      }

      if (event == AuthChangeEvent.signedOut) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _auth.currentSession;
    return session == null ? widget.loggedOut : widget.loggedIn;
  }
}
