import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final firebaseReady = await PushNotificationService.ensureInitialized();
  if (firebaseReady) {
    await PushNotificationService.ensureLocalNotificationsInitialized();
    await PushNotificationService.showNotificationFromMessage(message);
  }
  PushNotificationService.logBackgroundMessage(message);
}

class PushNotificationService {
  PushNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'driver_push_notifications',
    'Driver Push Notifications',
    description: 'Order and park notifications for drivers.',
    importance: Importance.high,
  );

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _firebaseReady = false;
  static bool _localNotificationsReady = false;
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final firebaseReady = await ensureInitialized();
    if (!firebaseReady) {
      _log('push init skipped: firebase unavailable');
      _initialized = true;
      return;
    }

    await ensureLocalNotificationsInitialized();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermissions();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (Object error) => _log('foreground push error: $error'),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedAppMessage,
      onError: (Object error) => _log('open-app push error: $error'),
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedAppMessage(initialMessage);
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      _log('fcm token: ${token ?? 'unavailable'}');
    } catch (error) {
      _log('fcm token unavailable: $error');
    }

    _initialized = true;
  }

  static Future<bool> ensureInitialized() async {
    if (_firebaseReady) {
      return true;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
      return true;
    } catch (error) {
      _log('firebase init failed: $error');
      return false;
    }
  }

  static Future<void> ensureLocalNotificationsInitialized() async {
    if (_localNotificationsReady) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _log('notification tapped: ${response.payload ?? 'no payload'}');
      },
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
    _localNotificationsReady = true;
  }

  static Future<void> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    _log('push permission status: ${settings.authorizationStatus}');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _log('foreground push: ${message.messageId ?? 'no-id'}');
    await showNotificationFromMessage(message);
  }

  static Future<void> showNotificationFromMessage(RemoteMessage message) async {
    await ensureLocalNotificationsInitialized();

    final notification = message.notification;
    final android = notification?.android;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'Notification';
    final body =
        notification?.body ?? message.data['body']?.toString() ?? 'New event';

    await _localNotificationsPlugin.show(
      notification.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: android?.smallIcon,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  static void _handleOpenedAppMessage(RemoteMessage message) {
    _log('push opened app: ${message.data}');
  }

  static void logBackgroundMessage(RemoteMessage message) {
    _log('background push: ${message.messageId ?? 'no-id'} ${message.data}');
  }

  static void _log(String message) {
    debugPrint('[push] $message');
  }
}
