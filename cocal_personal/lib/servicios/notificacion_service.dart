import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacionService {
  static final FlutterLocalNotificationsPlugin _notificaciones =
      FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initConfig =
        InitializationSettings(android: initAndroid);

    await _notificaciones.initialize(initConfig);
  }

  static Future<void> mostrarNotificacionInstantanea({
    required String titulo,
    required String cuerpo,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'canal_cocal',
      'Recordatorios CoCal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails detalles =
        NotificationDetails(android: androidDetails);

    await _notificaciones.show(0, titulo, cuerpo, detalles);
  }

  static Future<void> programarNotificacion({
    required String titulo,
    required String cuerpo,
    required DateTime fecha,
  }) async {
    final tiempo = tz.TZDateTime.from(fecha, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'canal_cocal',
      'Recordatorios CoCal',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificaciones.zonedSchedule(
      0,
      titulo,
      cuerpo,
      tiempo,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
