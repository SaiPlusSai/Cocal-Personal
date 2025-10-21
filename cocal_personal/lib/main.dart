import 'package:flutter/material.dart';
import 'app.dart';
import 'servicios/supabase_service.dart'; // 👈 importa el servicio

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar(); // 👈 corregido
  runApp(const AplicacionCoCal());
}
