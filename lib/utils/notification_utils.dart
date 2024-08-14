import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationUtils {
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String serverKey = "BJbfkA0cjhHVgHg_IcgE7mTiT06vrGA6wqpl4wWmf4fmjeeUCmC5fP1m5l_iO8OFK2ZuFqsMgaLSPoKDZV3KKnw"; // Replace with your server key

  Future<void> initialize() async {
    await Firebase.initializeApp();
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(RemoteMessage message) {
    print("Message received: ${message.notification?.title}");
  }

  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    final url = 'https://fcm.googleapis.com/fcm/send';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };
    final payload = jsonEncode({
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': {
        'title': title,
        'body': body,
      },
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: payload,
      );
      
      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }
}
