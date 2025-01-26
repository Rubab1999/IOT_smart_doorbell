import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'doorbell_channel',
    'Doorbell Notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: false,
    fullScreenIntent: true,
    tag: 'doorbell_notification', // Add tag to prevent duplicates
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? 'Doorbell Alert!',
    message.notification?.body ?? 'Someone is at your door!',
    notificationDetails,
    payload: message.data['doorbellId'],
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission with all options
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
      announcement: true,
      carPlay: true,
    );

    // Only set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'doorbell_channel',
      'Doorbell Notifications',
      description: 'Receives doorbell notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
    );

    // Create the channel on device
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize local notifications
    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidInitialize);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped with payload: ${details.payload}');
      },
    );

    // Only handle app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.messageId}');
      print('Payload: ${message.data}');
    });

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      print('FCM Token refreshed: $token');
    });
  }

  Future<void> subscribeToDoorbell(String doorbellId) async {
    final topic = 'doorbell_$doorbellId';
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromDoorbell(String doorbellId) async {
    final topic = 'doorbell_$doorbellId';
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
