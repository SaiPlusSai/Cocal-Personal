import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacionService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 🧭 Inicializa las notificaciones locales
  static Future<void> inicializar() async {
    // Inicializar zonas horarias
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

    // Inicialización general
    await _plugin.initialize(initSettings);

    // 🔒 Pedir permisos en Android 13+ y iOS
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// 🔔 Programa una notificación en una fecha y hora específica
  static Future<void> programarNotificacion({
    required String titulo,
    required String cuerpo,
    required DateTime fecha, // Fecha local
    int id = 0,
  }) async {
    // Convertimos la fecha local a zona horaria correcta
    final tzTime = tz.TZDateTime.from(fecha, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'cocal_recordatorios', // ID único del canal
      'Recordatorios de eventos', // Nombre del canal
      channelDescription: 'Notifica antes de que empiecen los eventos',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      tzTime,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  
  static Future<void> cancelarNotificacion(int id) async {
    await _plugin.cancel(id);
  }

  
  static Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }

  
  static Future<bool> permisosOtorgados() async {
    final permisos =
        await _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? granted = await permisos?.areNotificationsEnabled();
    return granted ?? false;
  }
}
