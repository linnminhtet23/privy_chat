import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:privy_chat/constant/app_theme.dart';
import 'package:privy_chat/providers/auth_provider.dart';
import 'package:privy_chat/providers/user_provider.dart';
import 'package:privy_chat/providers/theme_provider.dart';
import 'package:privy_chat/screens/home.dart';
import 'package:privy_chat/utils/notification_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    final notificationService = NotificationUtils();
    await notificationService.initialize();

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
  final AppTheme appTheme = AppTheme(); // Create an instance of AppTheme

  MyApp({super.key, required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider(navigatorKey)),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flutter Chat',
            theme: appTheme.light, // Use instance member
            darkTheme: appTheme.dark, // Use instance member
            themeMode: themeProvider.themeMode, // This line uses the ThemeProvider
            // home: isLoggedIn ?  HomeScreen() : const Login(),
            home: HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

