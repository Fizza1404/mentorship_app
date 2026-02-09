import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mentorship_channel', 
      'Mentorship Notifications',
      description: 'Notifications for assignments and updates',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  static Future<void> subscribeToTopic(String topic) async {
    String cleanTopic = topic.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
    await _fcm.subscribeToTopic(cleanTopic);
    print("Subscribed to topic: $cleanTopic");
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mentorship_channel', 
      'Mentorship Notifications',
      importance: Importance.max, 
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      message.notification?.title ?? "New Update",
      message.notification?.body ?? "",
      const NotificationDetails(android: androidDetails),
    );
  }

  // --- FCM V1 API TOKEN GENERATION ---
  static Future<String> getAccessToken() async {
    final serviceAccountContent = await rootBundle.loadString('service-account.json');
    final serviceAccount = json.decode(serviceAccountContent);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    
    final client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccount),
      scopes,
    );

    final credentials = client.credentials;
    return credentials.accessToken.data;
  }

  // --- SEND NOTIFICATION USING V1 ---
  static Future<void> sendNotification({
    required String toTopic,
    required String title,
    required String body,
  }) async {
    try {
      final String accessToken = await getAccessToken();
      final serviceAccountContent = await rootBundle.loadString('service-account.json');
      final String projectId = json.decode(serviceAccountContent)['project_id'];

      String cleanTopic = toTopic.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'topic': cleanTopic,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'notification': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'sound': 'default',
              }
            }
          }
        }),
      );

      print("FCM V1 Response: ${response.body}");
    } catch (e) {
      print("Error sending V1 notification: $e");
    }
  }
}