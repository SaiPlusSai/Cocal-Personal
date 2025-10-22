import 'package:flutter/material.dart';
import 'app.dart';
import 'servicios/notificacion_service.dart';
import 'servicios/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  await NotificacionService.inicializar();

  // 🧪 PRUEBA AUTOMÁTICA DE NOTIFICACIÓN EN 5 SEGUNDOS
  Future.delayed(const Duration(seconds: 5), () async {
    print('🧪 Disparando notificación de prueba...');
    await NotificacionService.programarNotificacion(
      titulo: '🚨 Test inmediato',
      cuerpo: 'Si ves esta notificación, todo funciona 🔥',
      fecha: DateTime.now().add(const Duration(seconds: 3)),
    );
  });

  runApp(const AplicacionCoCal());
}
