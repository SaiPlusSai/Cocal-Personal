import 'package:flutter/material.dart';
import 'app.dart';
import 'servicios/supabase_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar(); 
  runApp(const AplicacionCoCal());
}
