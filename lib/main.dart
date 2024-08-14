import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:secure_flutter_chat/providers/auth_provider.dart';
import 'package:secure_flutter_chat/providers/user_provider.dart';
import 'package:secure_flutter_chat/screens/home.dart';
import 'package:secure_flutter_chat/screens/login.dart';
import 'package:secure_flutter_chat/utils/notification_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background messages here
  print("Handling a background message: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    final notificationService = NotificationUtils();
    await notificationService.initialize(); // Initialize NotificationService

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    runApp(MyApp(isLoggedIn: isLoggedIn));
  } catch (e) {
    print('Error initializing Firebase or SharedPreferences: $e');
    runApp(MyApp(isLoggedIn: false)); // Default to not logged in if there's an error
  }
}

class MyApp extends StatelessWidget {
    final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider(navigatorKey)),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Flutter Chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: isLoggedIn ?  const HomeScreen() : const Login(),
      ),
    );
  }
}
