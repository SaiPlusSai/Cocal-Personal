import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/navigation.dart';
import 'supabase_service.dart';

class NotificacionSistemaService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Mapa de timers de polling por usuario (fallback cuando Realtime no entregue eventos)
  static final Map<int, Timer> _pollingTimers = {};
  // Último id visto por usuario
  static final Map<int, int> _ultimoIdVistoPorUsuario = {};

  /// 🚀 Inicializa las notificaciones del sistema
  static Future<void> inicializar() async {
    print('📱 [NotificacionSistemaService] Inicializando notificaciones del sistema...');

    // Configurar inicialización
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📩 [NotificacionSistemaService] Notificación del sistema tocada: ${response.payload}');
        _manejarNotificacionTocada(response.payload);
      },
    );

    // Si la app fue abierta desde una notificación cuando estaba terminada,
    // getNotificationAppLaunchDetails devuelve info sobre esa notificación.
    try {
      final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && (details.didNotificationLaunchApp ?? false)) {
        final payload = details.notificationResponse?.payload;
        print('📲 [NotificacionSistemaService] App lanzada por notificación con payload: $payload');
        // Esperar un frame para que el navigator esté listo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _manejarNotificacionTocada(payload);
        });
      }
    } catch (e) {
      print('⚠️ [NotificacionSistemaService] Error comprobando launch details: $e');
    }

    // Configurar canales específicos del sistema
    await _configurarCanalesSistema();

    // Suscribirse a cambios en "solicitudes" para recibir notificaciones push locales
    // cuando alguien envía una solicitud de amistad al usuario autenticado.
    try {
      await suscribirseSolicitudesRecibidas();
    } catch (e) {
      print('⚠️ [NotificacionSistemaService] Error durante suscripción de solicitudes: $e');
    }

    print('✅ [NotificacionSistemaService] Notificaciones del sistema inicializadas');
  }

  /// 🔔 Suscribe al cliente actual a inserciones en la tabla `solicitudes`
  /// y muestra una notificación del sistema cuando llega una nueva solicitud.
  static Future<void> suscribirseSolicitudesRecibidas() async {
    print('🔔 [NotificacionSistemaService] Iniciando suscripción a solicitudes...');
    
    try {
      final authUser = SupabaseService.cliente.auth.currentUser;
      print('👤 [NotificacionSistemaService] Usuario actual: ${authUser?.email}');
      
      if (authUser == null || authUser.email == null) {
        print('⚠️ [NotificacionSistemaService] No hay usuario autenticado para suscribirse a solicitudes');
        return;
      }

      // Obtener el id del usuario en la tabla `usuario`
      final correo = authUser.email!;
      print('🔍 [NotificacionSistemaService] Buscando usuario con correo: $correo');
      
      final usuarioRow = await SupabaseService.cliente
          .from('usuario')
          .select('id')
          .eq('correo', correo)
          .maybeSingle();

      if (usuarioRow == null) {
        print('⚠️ [NotificacionSistemaService] No se encontró fila de usuario para correo: $correo');
        return;
      }

      final miId = usuarioRow['id'] as int;
      print('✅ [NotificacionSistemaService] Usuario encontrado con id=$miId');

      // Inicializar último id visto consultando la fila más reciente
      try {
        final latest = await SupabaseService.cliente
            .from('solicitudes')
            .select('id')
            .eq('id_usuario', miId)
            .order('id', ascending: false)
            .limit(1);

        if (latest is List && latest.isNotEmpty) {
          final lastRow = latest[0];
          final rawId = lastRow['id'];
          int parsedId = 0;
          if (rawId is int) parsedId = rawId;
          else if (rawId is num) parsedId = rawId.toInt();
          else if (rawId is String) parsedId = int.tryParse(rawId) ?? 0;
          _ultimoIdVistoPorUsuario[miId] = parsedId;
          print('🔎 [NotificacionSistemaService] Último id inicial para polling: $parsedId');
        } else {
          _ultimoIdVistoPorUsuario[miId] = 0;
        }
      } catch (e) {
        print('⚠️ [NotificacionSistemaService] No se pudo obtener último id inicial: $e');
        _ultimoIdVistoPorUsuario[miId] = 0;
      }

      // Usar RealtimeChannel para escuchar cambios en solicitudes
      print('📡 [NotificacionSistemaService] Creando canal realtime...');
      final channel = SupabaseService.cliente.channel('public:solicitudes:$miId');
      
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'solicitudes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id_usuario',
          value: miId.toString(),
        ),
        callback: (payload) {
          print('🔔 [NotificacionSistemaService] Evento INSERT recibido: $payload');
          try {
            final nuevaSolicitud = payload.newRecord;
            if (nuevaSolicitud == null) {
              print('⚠️ [NotificacionSistemaService] newRecord es null');
              return;
            }

            print('📦 [NotificacionSistemaService] Nuevo registro: $nuevaSolicitud');
            
            final nombreRemitente = nuevaSolicitud['nombre_remitente'] as String? ?? 'Alguien';
            final idRemitente = nuevaSolicitud['id_remitente']?.toString() ?? '';

            print('👥 [NotificacionSistemaService] Mostrando notificación: $nombreRemitente (id=$idRemitente)');
            
            mostrarSolicitudAmistad(
              nombreUsuario: nombreRemitente,
              usuarioId: idRemitente,
            );
            // Actualizar último id visto para evitar duplicados entre realtime y polling
            try {
              final rawId = nuevaSolicitud['id'];
              int parsedId = 0;
              if (rawId is int) parsedId = rawId;
              else if (rawId is num) parsedId = rawId.toInt();
              else if (rawId is String) parsedId = int.tryParse(rawId) ?? 0;
              if (parsedId > 0) _ultimoIdVistoPorUsuario[miId] = parsedId;
            } catch (_) {}
          } catch (e) {
            print('❌ [NotificacionSistemaService] Error procesando solicitud: $e');
          }
        },
      );

      print('🔗 [NotificacionSistemaService] Suscribiendo al canal...');
      await channel.subscribe();
      // Iniciar polling como fallback (comprobaciones periódicas)
      _iniciarPollingSolicitudes(miId);

      print('✅ [NotificacionSistemaService] Suscripción realtime iniciada para usuario id=$miId');
    } catch (e) {
      print('❌ [NotificacionSistemaService] Error al suscribirse a solicitudes: $e');
      rethrow;
    }
  }

  /// ⚙️ Configura canales específicos para notificaciones del sistema
  static Future<void> _configurarCanalesSistema() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Canal para notificaciones de amistad
      const AndroidNotificationChannel canalAmistad = AndroidNotificationChannel(
        'cocal_amistades',
        'Solicitudes de Amistad',
        description: 'Notificaciones para solicitudes y actividades de amigos',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      // Canal para notificaciones sociales
      const AndroidNotificationChannel canalSocial = AndroidNotificationChannel(
        'cocal_social',
        'Actividad Social',
        description: 'Notificaciones sobre interacciones sociales',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Canal para notificaciones del sistema
      const AndroidNotificationChannel canalSistema = AndroidNotificationChannel(
        'cocal_sistema',
        'Notificaciones del Sistema',
        description: 'Notificaciones generales del sistema',
        importance: Importance.defaultImportance,
        playSound: true,
      );

      // Crear los canales
      await androidPlugin.createNotificationChannel(canalAmistad);
      await androidPlugin.createNotificationChannel(canalSocial);
      await androidPlugin.createNotificationChannel(canalSistema);

      print('📡 [NotificacionSistemaService] Canales del sistema configurados');
    }
  }

  /// 👥 Muestra notificación de solicitud de amistad
  static Future<void> mostrarSolicitudAmistad({
    required String nombreUsuario,
    required String usuarioId,
  }) async {
    print('👥 [NotificacionSistemaService] Mostrando solicitud de amistad de: $nombreUsuario');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_amistades',
      'Solicitudes de Amistad',
      channelDescription: 'Notificaciones para solicitudes y actividades de amigos',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.social,
      ticker: 'Nueva solicitud de amistad',
      styleInformation: BigTextStyleInformation(
        '$nombreUsuario quiere ser tu amigo',
        contentTitle: 'Solicitud de amistad',
        summaryText: 'Nueva solicitud',
      ),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'solicitudAmistad',
      threadIdentifier: 'amistades',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      'Solicitud de amistad',
      '$nombreUsuario quiere ser tu amigo',
      details,
      payload: 'solicitudes',
    );

    print('✅ [NotificacionSistemaService] Notificación de amistad mostrada');
  }

  /// ✅ Muestra notificación de amistad aceptada
  static Future<void> mostrarAmistadAceptada({
    required String nombreUsuario,
  }) async {
    print('✅ [NotificacionSistemaService] Mostrando amistad aceptada de: $nombreUsuario');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_social',
      'Actividad Social',
      channelDescription: 'Notificaciones sobre interacciones sociales',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.social,
      styleInformation: BigTextStyleInformation(
        '$nombreUsuario aceptó tu solicitud de amistad',
        contentTitle: '¡Amistad aceptada!',
        summaryText: 'Nueva amistad',
      ),
    );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      '¡Amistad aceptada!',
      '$nombreUsuario aceptó tu solicitud de amistad',
      details,
    );
  }

  /// 🔔 Muestra notificación de nuevo seguidor
  static Future<void> mostrarNuevoSeguidor({
    required String nombreUsuario,
  }) async {
    print('🔔 [NotificacionSistemaService] Mostrando nuevo seguidor: $nombreUsuario');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_social',
      'Actividad Social',
      channelDescription: 'Notificaciones sobre interacciones sociales',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.social,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      'Nuevo seguidor',
      '$nombreUsuario empezó a seguirte',
      details,
    );
  }

  /// 📅 Muestra notificación de evento compartido
  static Future<void> mostrarEventoCompartido({
    required String nombreUsuario,
    required String nombreEvento,
  }) async {
    print('📅 [NotificacionSistemaService] Mostrando evento compartido por: $nombreUsuario');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_social',
      'Actividad Social',
      channelDescription: 'Notificaciones sobre interacciones sociales',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.social,
      styleInformation: BigTextStyleInformation(
        '$nombreUsuario compartió "$nombreEvento" contigo',
        contentTitle: 'Evento compartido',
        summaryText: 'Evento compartido',
      ),
    );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      'Evento compartido',
      '$nombreUsuario compartió "$nombreEvento" contigo',
      details,
    );
  }

  /// 🎉 Muestra notificación de evento próximo (sistema)
  static Future<void> mostrarEventoProximo({
    required String nombreEvento,
    required int minutosRestantes,
  }) async {
    print('🎉 [NotificacionSistemaService] Mostrando evento próximo: $nombreEvento');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_sistema',
      'Notificaciones del Sistema',
      channelDescription: 'Notificaciones generales del sistema',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.event,
      styleInformation: BigTextStyleInformation(
        'Tu evento "$nombreEvento" comienza en $minutosRestantes minutos',
        contentTitle: 'Evento próximo',
        summaryText: 'Recordatorio de evento',
      ),
    );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      '⏰ Evento próximo',
      '"$nombreEvento" en $minutosRestantes minutos',
      details,
    );
  }

  /// 🚀 Muestra notificación de evento que comienza ahora
  static Future<void> mostrarEventoComienzaAhora({
    required String nombreEvento,
  }) async {
    print('🚀 [NotificacionSistemaService] Mostrando evento que comienza: $nombreEvento');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_sistema',
      'Notificaciones del Sistema',
      channelDescription: 'Notificaciones generales del sistema',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.event,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      '🚀 ¡Evento comenzando!',
      '"$nombreEvento" está comenzando ahora',
      details,
    );
  }

  /// 📱 Muestra notificación general del sistema
  static Future<void> mostrarNotificacionSistema({
    required String titulo,
    required String mensaje,
    String? tipo,
  }) async {
    print('📱 [NotificacionSistemaService] Mostrando notificación del sistema: $titulo');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_sistema',
      'Notificaciones del Sistema',
      channelDescription: 'Notificaciones generales de la aplicación',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      titulo,
      mensaje,
      details,
    );
  }

  /// 🔄 Muestra notificación de sincronización completada
  static Future<void> mostrarSincronizacionCompletada() async {
    print('🔄 [NotificacionSistemaService] Mostrando sincronización completada');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cocal_sistema',
      'Notificaciones del Sistema',
      channelDescription: 'Notificaciones generales de la aplicación',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      'Sincronización completada',
      'Todos tus datos están actualizados',
      details,
    );
  }

  /// 🎯 Muestra notificación de recordatorio personalizado
  static Future<void> mostrarRecordatorioPersonalizado({
    required String titulo,
    required String mensaje,
    required String canal,
  }) async {
    print('🎯 [NotificacionSistemaService] Mostrando recordatorio personalizado: $titulo');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      canal,
      'Notificaciones Personalizadas',
      channelDescription: 'Notificaciones personalizadas del usuario',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      id,
      titulo,
      mensaje,
      details,
    );
  }

  /// 🗑️ Cancela todas las notificaciones del sistema
  static Future<void> cancelarTodas() async {
    print('🧹 [NotificacionSistemaService] Cancelando todas las notificaciones del sistema');
    await _notificationsPlugin.cancelAll();
  }

  /// 🗑️ Cancela una notificación específica del sistema
  static Future<void> cancelarNotificacion(int id) async {
    print('🧹 [NotificacionSistemaService] Cancelando notificación del sistema ID: $id');
    await _notificationsPlugin.cancel(id);
  }

  /// 🔒 Verifica permisos de notificación del sistema
  static Future<bool> verificarPermisos() async {
    if (_notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>() != null) {
      final permisos = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return permisos ?? false;
    }
    return false;
  }

  /// 🎯 Maneja cuando se toca una notificación del sistema
  static void _manejarNotificacionTocada(String? payload) {
    print('🎯 [NotificacionSistemaService] Notificación del sistema tocada con payload: $payload');

    try {
      // Intentar navegar inmediatamente si el navigator está listo
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.pushNamed('/solicitudes');
        print('🎯 [NotificacionSistemaService] Navegando a /solicitudes (inmediato)');
        return;
      }

      // Si no está listo, guardar intent en shared_preferences para ejecutar en el startup
      _guardarIntentNavegacion('/solicitudes');
    } catch (e) {
      print('❌ [NotificacionSistemaService] Error navegando desde notificación: $e');
      _guardarIntentNavegacion('/solicitudes');
    }
  }

  /// Guardar intent de navegación en shared_preferences
  static Future<void> _guardarIntentNavegacion(String ruta) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('navigation_intent', ruta);
      print('💾 [NotificacionSistemaService] Intent guardado: $ruta');
    } catch (e) {
      print('⚠️ [NotificacionSistemaService] Error guardando intent: $e');
    }
  }

  /// Comprobar y ejecutar intent de navegación pendiente (llamar desde main/startup)
  static Future<void> ejecutarIntentPendiente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ruta = prefs.getString('navigation_intent');
      if (ruta != null && ruta.isNotEmpty) {
        print('🔄 [NotificacionSistemaService] Ejecutando intent pendiente: $ruta');
        await prefs.remove('navigation_intent');

        // Esperar un frame para que el navigator esté listo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = navigatorKey.currentState;
          if (nav != null) {
            nav.pushNamed(ruta);
            print('🎯 [NotificacionSistemaService] Navegando a $ruta (desde intent pendiente)');
          }
        });
      }
    } catch (e) {
      print('⚠️ [NotificacionSistemaService] Error ejecutando intent pendiente: $e');
    }
  }

  /// Inicia un polling periódico como fallback para detectar nuevas solicitudes
  static void _iniciarPollingSolicitudes(int miId) {
    // Si ya hay un timer, no crear otro
    if (_pollingTimers.containsKey(miId)) return;

    final timer = Timer.periodic(const Duration(seconds: 5), (t) async {
      try {
        final latest = await SupabaseService.cliente
            .from('solicitudes')
            .select()
            .eq('id_usuario', miId)
            .order('id', ascending: false)
            .limit(1);

        if (latest is List && latest.isNotEmpty) {
          final row = latest[0];
          final rawId = row['id'];
          int parsedId = 0;
          if (rawId is int) parsedId = rawId;
          else if (rawId is num) parsedId = rawId.toInt();
          else if (rawId is String) parsedId = int.tryParse(rawId) ?? 0;

          final lastSeen = _ultimoIdVistoPorUsuario[miId] ?? 0;
          if (parsedId > 0 && parsedId > lastSeen) {
            _ultimoIdVistoPorUsuario[miId] = parsedId;
            final nombreRemitente = row['nombre_remitente']?.toString() ?? 'Alguien';
            final idRemitente = row['id_remitente']?.toString() ?? '';
            print('🕵️ [NotificacionSistemaService] Polling detectó nueva solicitud id=$parsedId');
            mostrarSolicitudAmistad(nombreUsuario: nombreRemitente, usuarioId: idRemitente);
          }
        }
      } catch (e) {
        print('⚠️ [NotificacionSistemaService] Error en polling de solicitudes: $e');
      }
    });

    _pollingTimers[miId] = timer;
    print('⏱️ [NotificacionSistemaService] Polling iniciado para usuario id=$miId');
  }

  /// Detiene el polling para un usuario
  static void _detenerPollingSolicitudes(int miId) {
    final timer = _pollingTimers.remove(miId);
    if (timer != null) {
      timer.cancel();
      print('⏹️ [NotificacionSistemaService] Polling detenido para usuario id=$miId');
    }
  }
}