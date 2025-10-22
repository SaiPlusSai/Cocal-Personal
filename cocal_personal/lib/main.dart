import 'package:flutter/material.dart';
import 'app.dart';
import 'servicios/notificacion_service.dart';
import 'servicios/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  await NotificacionService.inicializar(); // 👈
  runApp(const AplicacionCoCal());
}
