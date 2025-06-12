import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:listener_app/app.dart';
import 'package:listener_app/core/widgets/incoming_call_dialog.dart';
import 'package:listener_app/features/splash/views/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseMessagingService.instance.setupFlutterNotifications();
  await FirebaseMessagingService.instance._handleMessage(message);
}

class FirebaseMessagingService {
  FirebaseMessagingService._();
  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _requestMicrophonePermissions(navigatorKey);
    await setupFlutterNotifications();

    FirebaseMessaging.onMessage.listen((message) {
      _handleMessage(message, navigatorKey: navigatorKey);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message, navigatorKey: navigatorKey);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, navigatorKey: navigatorKey);
    }

    debugPrint('FCM Token: ${await _messaging.getToken()}');
  }

  Future<void> _requestMicrophonePermissions(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      debugPrint('FCM: Microphone permission denied');
      if (navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) => AlertDialog(
            title: const Text('Microphone Permission Required'),
            content: const Text(
              'This app requires microphone access to handle calls. Please enable it in settings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else if (status.isGranted) {
      debugPrint('FCM: Microphone permission granted');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for call notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SplashScreen(isListenerApp: true),
          ),
        );
      },
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isFlutterLocalNotificationsInitialized = true;
    debugPrint('FCM: Local notifications initialized');
  }

  Future<void> _handleMessage(
    RemoteMessage message, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    final type = message.data['type'];
    debugPrint('FCM: Received message, type: $type');

    if (type == 'call_request') {
      await _showLocalNotification(
        message.notification?.title ?? 'Incoming Call',
        message.notification?.body ?? 'You have a new call request',
      );

      if (navigatorKey?.currentContext != null &&
          await Permission.microphone.isGranted) {
        debugPrint('FCM: Showing incoming call dialog');
        showDialog(
          context: navigatorKey!.currentContext!,
          barrierDismissible: false,
          builder: (context) => IncomingCallDialog(
            callRequestId: message.data['callRequestId']!,
            callerEmail: message.data['callerEmail']!,
            callerId: message.data['callerId']!,
            channelName: message.data['agoraChannelName']!,
          ),
        );
      } else {
        debugPrint(
          'FCM: Cannot show call dialog, microphone permission denied or context null',
        );
      }
    } else {
      await _showLocalNotification(
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
      );
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iOSDetails),
    );
    debugPrint('FCM: Showed local notification: $title');
  }

  Future<String?> getFCMToken() async => _messaging.getToken();
}
