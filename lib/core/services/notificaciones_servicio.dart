import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/partidos/domain/partido.dart';
import '../../features/quinielas/domain/quiniela_models.dart';
import '../router/rutas.dart';
import '../theme/tds_colors.dart';

/// Proveedor global singleton del servicio de notificaciones.
final notificacionesServicioProvider = Provider<NotificacionesServicio>((ref) {
  return NotificacionesServicio();
});

/// Servicio de Notificaciones Locales (Anti-Olvido) enfocado en Android.
///
/// Permite programar recordatorios en la barra de notificaciones del celular
/// para partidos que están por comenzar cuando el usuario aún no ha realizado
/// su pronóstico.
class NotificacionesServicio {
  static final NotificacionesServicio _instancia = NotificacionesServicio._interno();
  factory NotificacionesServicio() => _instancia;
  NotificacionesServicio._interno();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  /// Canal principal de notificaciones para Android
  static const String canalPartidosId = 'tds_partidos_recordatorios';
  static const String canalPartidosNombre = 'Recordatorios de Partidos';
  static const String canalPartidosDesc =
      'Avisos de partidos por iniciar para no olvidar pronosticar.';

  /// Inicializa el plugin, zonas horarias y crea el canal en Android.
  Future<void> inicializar({void Function(String? payload)? onSelectNotification}) async {
    if (_inicializado) return;

    if (kIsWeb) {
      // En Web las notificaciones locales del SO no aplican directamente
      _inicializado = true;
      return;
    }

    try {
      // 1. Inicializar base de datos de zonas horarias para alarmas exactas
      tz.initializeTimeZones();

      // 2. Configuración para Android usando el icono oficial de la app
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración para iOS / Darwin
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && onSelectNotification != null) {
            onSelectNotification(payload);
          }
        },
      );

      // 3. Crear el canal de notificación de alta prioridad en Android
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            canalPartidosId,
            canalPartidosNombre,
            description: canalPartidosDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _inicializado = true;
      dev.log('Notificaciones locales inicializadas con éxito.', name: 'TdsNotificaciones');
    } catch (e, st) {
      dev.log('Error al inicializar notificaciones: $e', name: 'TdsNotificaciones', error: e, stackTrace: st);
    }
  }

  /// Solicita permisos de notificación en Android 13+ (POST_NOTIFICATIONS)
  Future<bool> solicitarPermisos() async {
    if (kIsWeb) return false;

    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final concedido = await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        return concedido ?? false;
      }
      return false;
    } catch (e) {
      dev.log('Error al solicitar permisos: $e', name: 'TdsNotificaciones');
      return false;
    }
  }

  /// Muestra una notificación inmediata en el celular (útil para pruebas o alertas urgentes)
  Future<void> mostrarNotificacionInmediata({
    required int id,
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await inicializar();

    const androidDetails = AndroidNotificationDetails(
      canalPartidosId,
      canalPartidosNombre,
      channelDescription: canalPartidosDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: TdsColors.acento,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: details,
      payload: payload ?? Rutas.misPronosticosPendientes(),
    );
  }

  /// Programa un recordatorio para un partido específico [anticipacion] antes del silbatazo.
  ///
  /// Por defecto se programa 1 hora antes (`Duration(hours: 1)`).
  Future<void> programarRecordatorioPartido({
    required Partido partido,
    required String quinielaNombre,
    Duration anticipacion = const Duration(hours: 1),
  }) async {
    if (kIsWeb) return;
    await inicializar();

    final fechaPartido = partido.fecha;
    if (fechaPartido == null) return;

    final horaAlerta = fechaPartido.subtract(anticipacion);
    final ahora = DateTime.now();

    // Solo programar si la hora de la alerta aún está en el futuro
    if (horaAlerta.isBefore(ahora)) return;

    final tzHoraAlerta = tz.TZDateTime.from(horaAlerta, tz.local);

    // ID numérico único basado en el hash del partido
    final notifId = partido.id.hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      canalPartidosId,
      canalPartidosNombre,
      channelDescription: canalPartidosDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: TdsColors.acento,
      ticker: 'Recordatorio de Quiniela',
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        id: notifId,
        title: '⏰ ¡No olvides tu pronóstico!',
        body: '${partido.local.nombre} vs ${partido.visitante.nombre} inicia en ${anticipacion.inMinutes} min. '
            'Asigna tu marcador en "$quinielaNombre".',
        scheduledDate: tzHoraAlerta,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: Rutas.misPronosticosPendientes(),
      );
      dev.log(
        'Alerta programada para ${partido.local.nombre} vs ${partido.visitante.nombre} a las $horaAlerta',
        name: 'TdsNotificaciones',
      );
    } catch (e) {
      dev.log('Error al programar alerta con zonedSchedule: $e', name: 'TdsNotificaciones');
    }
  }

  /// Sincroniza y programa automáticamente las alertas de todos los partidos
  /// de hoy y mañana que el usuario aún NO ha pronosticado.
  Future<void> sincronizarAlertasAntiOlvido(List<ResumenQuiniela> quinielas) async {
    if (kIsWeb || quinielas.isEmpty) return;
    await inicializar();

    final ahora = DateTime.now();
    final limiteVentana = ahora.add(const Duration(hours: 48));

    for (final q in quinielas) {
      for (final p in q.partidos) {
        final f = p.fecha;
        if (f == null) continue;

        // Si ya pasó o es más allá de 48 horas
        if (f.isBefore(ahora) || f.isAfter(limiteVentana)) continue;

        // Si aún no tiene pronóstico y acepta pronósticos
        final yaPronosticado = q.pronosticos.containsKey(p.id);
        if (!yaPronosticado && p.aceptaPronosticoEn(ahora)) {
          // Programar a 1 hora antes
          await programarRecordatorioPartido(
            partido: p,
            quinielaNombre: q.nombre,
            anticipacion: const Duration(hours: 1),
          );
        }
      }
    }
  }

  /// Cancela todas las notificaciones pendientes
  Future<void> cancelarTodas() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
