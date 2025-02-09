import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:privy_chat/push_notification/navigation_controller.dart';
import 'package:privy_chat/push_notification/notification_channels.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class NotificationServices {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static String? fcmToken;

  static Future<void> createNotificationChannelAndInitialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
          NotificationChennels.highInportanceChannel);
      await androidImplementation
          .createNotificationChannel(NotificationChennels.lowInportanceChannel);
    }
  }

  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "privychat-4bc01",
      "private_key_id": "c215f3ddbb8c6c5a3c7638a488897550efc49d3e",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC6lTp+7m4MvzZk\nikO12BeIZUkmj/DnZYMNjPPfXTedMEBYkWndmfGTQG5OnEp9Y1KcpOaMna6/zXPT\nK4HD6MwLx5cFqIpJdZI7PCXnRrq5XtwbCzu5Q+RorqPKG3n514ceoTQniwXmI/gT\nfP9OT/nZ2pOhDMFtcH0CwtaO5moWNS3OcqNHQ3K28qAjLGUX4e+l+qJQssfKM+gB\n2Gsc1rMHRsqkL6b7JFzHE86Wb/ireBOyBLg//Xo3WPSIgMU5kVNbTJSSfYJojmJr\niGvU0biLUgNxMwb7VuTWOkl/z80LS0FLz5qjQ9oVS/v33xaoAFbbLf+aVEGw5jDr\nRcji+UFdAgMBAAECggEABGH3EQQfAtMviqryZZSW5Ou0gZT4zJ008hVPpVp3yEZl\nd3IHsxLQaUNgxWNNcHJJIXC6tF0i7C+g8kWofClaT9KF4AemgEbHN2vM2/F4JdD/\npqg+wXu2Lut8VeMLnExb4AWhEwmeokML8MJW70JkTETFguDLx54WODAoElKYaflc\nSu48iVm1IbbTh8nVzo9lBv/IeqzSU6XYk3hHj7ds4k/F6SYcm4bzZkV/joVZHInH\n+Ll6sBpzV3Go64w6kQXL1Vnpj0PvWrfBHBrMS/flNC/NDqTrbjlO0GE4te/CGgi2\nFVzIgkKzzcf1xxBooPD2TwhqRDugdTIvKYz/KYuu7wKBgQD0u9L7yL2F9x+mLuAn\n/qwYZJT3GsYm1qGfVlVCa2E7x63r27UeaqhkDEwf049rAg0bJi/GVkXGBj2AyhrS\npDEKurmxA4z/bwYic+nEUND48hzlIJxCPtG+p1BbhrrAznH9b8Ehi0v1ZC255/g5\nPO/SFbeQT2JE4GkZU0Dw1117hwKBgQDDLBmhptzVWDhcs2szE9rzxT3+zBgMFRjV\nk8spHf4u+bQPi0E1d9UQ/qlat6FO26Zn0D+vTfrEzSO02j5RzMqIs+/ThsTmKTQp\nhoHi2s0N3ZmwGU5wdcvjKhPjuhkw+ojdA9TVo3T2CPCdXt6nbytH/YsU2P0a92a9\nuzuBWha8+wKBgB+wamNb3N6J3zk/fJrxKQuHippshxfkVs0w+p09FjwNYQHXUx57\nJQ6/YOQGGt36SAQp76m45hP8Ht6cTNjVldwTzZOUKB+zGpI/fBeFd2mkwAUTMeiK\nBdKwC4GucmQg1zW/0LwtM0q1DA60cLnIoC0NztUK0mikvjcfRpto55vlAoGAH5dT\nzsajmCTfeqHQCER+fFbA4i1G9y2zB18U02L3ccMZUirIM09iPY36+6QdiBYlqUgc\nBtQocxKBZRSuYa80WUxG1YZK+LZSqyYKgB3KcyQbbFWsTKfEiNCWx5Wn3jWvUZb9\nLFd45xorWE2y3IcyCkUP7h/xWBwTlUJpL1bVt2ECgYEA4SSerSL3psw3S2oJBAT2\ndr5lDx7wIIJvAl7DPgDcI0SYPfLnm2Kw6UxewAKBPmKF1JX0lsuyMhcgwcrSb/4r\n9c6j7eXoFZOpl8v4Jp7KOkWGwefUCWoiXnfJ4hBSCJ0ds7NNnx3c3FJHXVsf83Fj\nR3X0uhNDDU6xjDh0tBD+Mus=\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-y8fc6@privychat-4bc01.iam.gserviceaccount.com",
      "client_id": "102433137936932157465",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-y8fc6%40privychat-4bc01.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };
    
    final List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
    final client = await auth.clientViaServiceAccount(credentials, scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close(); // Important: Close the client to prevent resource leaks
    print(accessToken);
    return accessToken;
  }

  // static Future<void> sendNotification({
  //   required String token,
  //   required String title,
  //   required String body,
  //   required Map<String, dynamic> data,
  // }) async {
  //   try {
  //     log('Sending notification - Title: $title, Body: $body, Token: $token');
  //     log('Notification data: ${jsonEncode(data)}');

  //     final String accessToken = await getAccessToken();

  //     final Map<String, dynamic> message = {
  //       'message': {
  //         'token': token,
  //         'notification': {
  //           'title': title,
  //           'body': body
  //         },
  //         'android': {
  //           'notification': {
  //             'channelId': NotificationChennels.highInportanceChannel.id,
  //             'notification_count': 1
  //           }
  //         },
  //         'apns': {
  //           'payload': {
  //             'aps': {
  //               'sound': 'default',
  //               'badge': 1,
  //               'content-available': 1,
  //               'mutable-content': 1
  //             }
  //           },
  //           'headers': {
  //             'apns-priority': '10'
  //           }
  //         },
  //         'data': data
  //       }
  //     };

  //     final http.Response response = await http.post(
  //       Uri.parse('https://fcm.googleapis.com/v1/projects/privychat-4bc01/messages:send'),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $accessToken'
  //       },
  //       body: jsonEncode(message)
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = jsonDecode(response.body);
  //       log('Notification sent successfully. Response: ${response.body}');
  //       log('Success count: ${responseData['success'] ?? 1}, Failure count: ${responseData['failure'] ?? 0}');
  //     } else {
  //       log('Failed to send notification. Status code: ${response.statusCode}');
  //       log('Error response: ${response.body}');
  //     }
  //   } catch (e, stackTrace) {
  //     log('Error sending notification:', error: e, stackTrace: stackTrace);
  //   }
  // }
  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      log('Sending notification - Title: $title, Body: $body, Token: $token');
      log('Notification data: ${jsonEncode(data)}');

      final String accessToken = await getAccessToken();

          final Map<String, dynamic> message = {
            'message': {
              'token': token,
              'notification': {
                'title': title,
                'body': body,
                'image': data['senderImage'] ?? '',
              },
              'android': {
                'notification': {
                  'channelId': NotificationChennels.highInportanceChannel.id,
                  'notification_count': 1,
                  'image': data['senderImage'] ?? '',
                }
              },
              'apns': {
                'payload': {
                  'aps': {
                    'sound': 'default',
                    'badge': 1,
                    'content-available': 1,
                    'mutable-content': 1
                  }
                },
                'headers': {
                  'apns-priority': '10'
                }
              },
              'data': data
            }
          };

      final http.Response response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/privychat-4bc01/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode(message)
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        log('Notification sent successfully. Response: ${response.body}');
        log('Success count: ${responseData['success'] ?? 1}, Failure count: ${responseData['failure'] ?? 0}');
      } else {
        log('Failed to send notification. Status code: ${response.statusCode}');
        log('Error response: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error sending notification:', error: e, stackTrace: stackTrace);
    }
  }


  static Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // handle notification taps here on IOS
    log('Body: $body');
    log('payload: $payload');
  }

  static void onDidReceiveNotificationResponse(
      NotificationResponse notificationRespons) {
    log('onDidReceiveNotificationResponse : $notificationRespons');
    final payload = notificationRespons.payload;
    if (payload != null) {
      // convert payload to remoteMessage and handle interaction
      final message = RemoteMessage.fromMap(jsonDecode(payload));
      log('message: $message');
      navigationControler(
          context: navigatorKey.currentState!.context, message: message);
    }
  }

  static void onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationRespons) {
    log('BackgroundPayload : $notificationRespons');
  }

  static displayNotification(RemoteMessage message) {
    log('display notification: $message');
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = notification?.android;
    AppleNotification? apple = notification?.apple;
    String channelId = android?.channelId ?? 'default_channel';

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification?.title,
      notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, // Channel id.
          findChannelName(channelId), // Channel name.
          importance: Importance.max,
          playSound: true,
          icon: android?.smallIcon, // Optional icon to use.
        ),
        iOS: DarwinNotificationDetails(
          sound: apple?.sound?.name,
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
        ),
      ),
      payload: jsonEncode(message.toMap()),
    );
  }

  static String findChannelName(String channelId) {
    switch (channelId) {
      case 'high_importance_channel':
        return NotificationChennels.highInportanceChannel.name;
      case 'low_importance_channel':
        return NotificationChennels.lowInportanceChannel.name;
      default:
        return NotificationChennels.highInportanceChannel.name;
    }
  }
}
