import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationUtils {
  static const String _serverKey = "BCHgcQJYPeP7td0-mom9rq3DuJVPZRM2Vj96VVBm605qCWEZ6TTOI10xBYhIaosIjjOhR71pv5Z7zt5KtuLFhtg"; // Replace with your actual server key
  static const String _tokenKey = "device_token";
  
  // Reference to Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _typingTimer;
  static const _typingDuration = Duration(milliseconds: 1000); // Duration to consider user as typing

  Future<void> initialize() async {
    await Firebase.initializeApp();

    // Request notification permissions
    await _requestPermission();

    // Retrieve and store the device token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _storeDeviceToken(token);
    }

    // Set up message handlers
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _storeDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  void _handleMessage(RemoteMessage message) {
    print("Message received: ${message.notification?.title}");
    // Handle the received message (e.g., display notification, update data)
  }

  Future<void> sendNotification({
    required String token, // The recipient's device token
    required String title,
    required String body,
  }) async {
    final url = 'https://fcm.googleapis.com/fcm/send';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$_serverKey',
    };
    final payload = jsonEncode({
      'to': token, // Send the notification to the provided token
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

  // Update user typing status
  Future<void> updateTypingStatus({
    required String userId,
    required String chatRoomId,
    required bool isTyping,
  }) async {
    try {
      // Cancel any existing timer
      _typingTimer?.cancel();

      // Update typing status in Firestore
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'typingUsers.$userId': isTyping,
      });

      if (isTyping) {
        // Start timer to automatically set typing to false after duration
        _typingTimer = Timer(_typingDuration, () async {
          await _firestore.collection('chatRooms').doc(chatRoomId).update({
            'typingUsers.$userId': false,
          });
        });
      }
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }
}
