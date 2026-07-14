// lib/services/notification_service.dart  (VENDOR APP)

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendor/firebase_options.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

final GlobalKey<NavigatorState> vendorNavigatorKey =
    GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _bookingChannel =
      AndroidNotificationChannel(
        'booking_channel',
        'Booking Notifications',
        description: 'Notifications for new bookings',
        importance: Importance.max,
      );

  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Fix: use local variable to avoid chained ?. error ──────────────────
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_bookingChannel);
    await androidPlugin?.requestNotificationsPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Vendor notification tapped: ${response.payload}');
        _navigateToDashboard();
      },
    );

    // ── Foreground messages ─────────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '📩 Vendor foreground message: ${message.notification?.title}',
      );
      _showLocalNotification(message);
    });

    // ── Background tap ──────────────────────────────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Vendor background notification tapped');
      _navigateToDashboard();
    });

    // ── Terminated tap ──────────────────────────────────────────────────────
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message != null) {
        debugPrint('📩 Vendor terminated notification tapped');
        await Future.delayed(const Duration(milliseconds: 1000));
        _navigateToDashboard();
      }
    });

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('✅ Vendor NotificationService initialized');
  }

  void _navigateToDashboard() {
    final navigator = vendorNavigatorKey.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Vendor navigator not ready');
      return;
    }
    navigator.pushNamedAndRemoveUntil(
      AppConstants.dashboardRoute,
      (route) => false,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _bookingChannel.id,
          _bookingChannel.name,
          channelDescription: _bookingChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['type'] ?? 'new_order',
    );
  }

  Future<void> saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final user = Supabase.instance.client.auth.currentUser;

      debugPrint('📱 Vendor FCM token: $token');

      if (user != null && token != null) {
        await Supabase.instance.client
            .from('vendors') // ✅ confirmed from your schema
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('✅ Vendor FCM token saved');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          await Supabase.instance.client
              .from('vendors')
              .update({'fcm_token': newToken})
              .eq('id', currentUser.id);
          debugPrint('✅ Vendor FCM token refreshed');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Failed to save vendor FCM token: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _bookingChannel.id,
          _bookingChannel.name,
          channelDescription: _bookingChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
