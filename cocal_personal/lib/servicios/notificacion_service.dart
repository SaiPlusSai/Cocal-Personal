import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacionService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 🧭 Inicializa las notificaciones locales
  static Future<void> inicializar() async {
    print('🚀 [NotificacionService] Inicializando notificaciones locales...');
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('📩 [NotificacionService] Notificación tocada: ${response.payload}');
      },
    );

    // 🔒 Pedir permisos
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      print('✅ [NotificacionService] Permisos solicitados en Android.');
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      print('✅ [NotificacionService] Permisos solicitados en iOS.');
    }

    print('🎯 [NotificacionService] Inicialización completada correctamente.');
  }

  /// 🔔 Programa una notificación en una fecha y hora específica
  static Future<void> programarNotificacion({
    required String titulo,
    required String cuerpo,
    required DateTime fecha,
    int? id,
  }) async {
    print('🕒 [NotificacionService] Programando notificación: "$titulo"');
    print('   📅 Fecha objetivo: $fecha');

    DateTime fechaFinal = fecha.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(seconds: 5))
        : fecha;

    final tzTime = tz.TZDateTime.from(fechaFinal, tz.local);
    final notifId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

    print('   🧭 Fecha TZ local: $tzTime');
    print('   🆔 ID de notificación: $notifId');

    final androidDetails = AndroidNotificationDetails(
      'cocal_recordatorios',
      'Recordatorios de eventos',
      channelDescription: 'Notifica antes y durante los eventos programados',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'Evento próximo',
    );

    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        notifId,
        titulo,
        cuerpo,
        tzTime,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ [NotificacionService] Notificación "$titulo" programada exitosamente para $tzTime');
    } catch (e) {
      print('❌ [NotificacionService] Error al programar notificación "$titulo": $e');
    }
  }

  /// 🚀 Programa dos notificaciones: una antes del evento y otra al inicio exacto
  static Future<void> programarRecordatorioDoble({
    required String titulo,
    required DateTime fechaEvento,
    required int minutosAntes,
  }) async {
    print('\n🧩 [NotificacionService] Programando recordatorio doble para "$titulo"');
    print('   📆 Fecha evento: $fechaEvento');
    print('   ⏳ Minutos antes: $minutosAntes');

    final fechaRecordatorio = fechaEvento.subtract(Duration(minutes: minutosAntes));

    await programarNotificacion(
      titulo: '⏰ Recordatorio de evento',
      cuerpo: 'Tu evento "$titulo" empieza en $minutosAntes minutos.',
      fecha: fechaRecordatorio,
      id: fechaEvento.millisecondsSinceEpoch.remainder(100000),
    );

    await programarNotificacion(
      titulo: '🚀 ¡Tu evento ha comenzado!',
      cuerpo: 'Tu evento "$titulo" está comenzando ahora.',
      fecha: fechaEvento,
      id: (fechaEvento.millisecondsSinceEpoch.remainder(100000)) + 1,
    );

    print('🎉 [NotificacionService] Recordatorios doble programados correctamente.\n');
  }

  /// ❌ Cancela una notificación por su ID
  static Future<void> cancelarNotificacion(int id) async {
    print('🧹 [NotificacionService] Cancelando notificación ID $id...');
    await _plugin.cancel(id);
  }

  /// ❌ Cancela todas las notificaciones
  static Future<void> cancelarTodas() async {
    print('🧹 [NotificacionService] Cancelando todas las notificaciones...');
    await _plugin.cancelAll();
  }

  /// 🔐 Verifica si los permisos de notificación están otorgados
  static Future<bool> permisosOtorgados() async {
    final permisos = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final bool? granted = await permisos?.areNotificationsEnabled();
    print('🔒 [NotificacionService] Permisos otorgados: ${granted ?? false}');
    return granted ?? false;
  }
}
