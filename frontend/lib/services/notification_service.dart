import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get I => _instance;

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Skip on web (and allow the app to run without notifications)
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Timezone init
    tz.initializeTimeZones();
    try {
      final String localName = tz.local.name; // rely on device setting
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Fallback if timezone lookup fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _fln.initialize(initSettings);

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'mediremind_daily',
        'MediRemind Daily Reminders',
        description: 'Medicine time reminders',
        importance: Importance.high,
      );
      final androidPlugin = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await init();
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final androidPlugin = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidPlugin?.areNotificationsEnabled() ?? true;
      if (!enabled) {
        await androidPlugin?.requestPermission();
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _fln.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await init();
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'mediremind_daily',
      'MediRemind Daily Reminders',
      channelDescription: 'Medicine time reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      ticker: 'MediRemind',
    );
    const iosDetails = IOSNotificationDetails();

    final details = const NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _fln.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    if (kIsWeb) return;
    await _fln.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    if (kIsWeb) return;
    await _fln.cancelAll();
  }
}

extension NotificationServiceTesting on NotificationService {
  Future<void> showTestNotification() async {
    await init();
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'mediremind_daily',
      'MediRemind Daily Reminders',
      channelDescription: 'Medicine time reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      ticker: 'MediRemind',
    );
    const iosDetails = IOSNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _fln.show(
      999000,
      'Test notification',
      'If you see this, local notifications work!',
      details,
    );
  }
}
