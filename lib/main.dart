
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privy_chat/authentication/landing_screen.dart';
import 'package:privy_chat/authentication/login_screen.dart';
import 'package:privy_chat/authentication/opt_screen.dart';
import 'package:privy_chat/authentication/register_screen.dart';
import 'package:privy_chat/authentication/user_information_screen.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/firebase_options.dart';
import 'package:privy_chat/main_screen/chat_screen.dart';
import 'package:privy_chat/main_screen/friend_requests_screen.dart';
import 'package:privy_chat/main_screen/friends_screen.dart';
import 'package:privy_chat/main_screen/group_information_screen.dart';
import 'package:privy_chat/main_screen/group_settings_screen.dart';
import 'package:privy_chat/main_screen/home_screen.dart';
import 'package:privy_chat/main_screen/profile_screen.dart';
import 'package:privy_chat/providers/authentication_provider.dart';
import 'package:privy_chat/providers/chat_provider.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:provider/provider.dart';

import 'screens/onboarding_screen.dart';

// import 'utils/encryptionutilsnewapproach.dart';


@pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // If you're going to use other Firebase services in the background, such as Firestore,
//   // await Firebase.initializeApp();
//   await FirebaseMessaging.instance.subscribeToTopic("topic");
//   log("Handling a background message: ${message.messageId}");
//   log("Handling a background message: ${message.notification!.title}");
//   log("Handling a background message: ${message.notification!.body}");
//   log("Handling a background message: ${message.data}");
// }

// Global variable to track first-time app launch
// bool isFirstTime = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  // final prefs = await SharedPreferences.getInstance();
  // isFirstTime = prefs.getBool('isFirstTime') ?? true;
  //
  // if (isFirstTime) {
  //   await prefs.setBool('isFirstTime', false);
  // }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // await FirebaseMessaging.instance.subscribeToTopic("app");

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        // ChangeNotifierProvider(create: (_) => AuthenticationCopyProvider()),

        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MyApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.savedThemeMode});

  final AdaptiveThemeMode? savedThemeMode;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Privy Chat',
        theme: theme,
        darkTheme: darkTheme,
        initialRoute: Constants.landingScreen, // Show onboarding for first time users
        routes: {
          // '/': (context) => const OnboardingScreen(),
          Constants.landingScreen: (context) => const LandingScreen(),
          Constants.loginScreen: (context) => const LoginScreen(),
          Constants.registerScreen: (context) => const RegisterScreen(),

          Constants.otpScreen: (context) => const OTPScreen(),
          Constants.userInformationScreen: (context) =>
              const UserInformationScreen(),
          Constants.homeScreen: (context) => const HomeScreen(),
          Constants.profileScreen: (context) => const ProfileScreen(),
          Constants.friendsScreen: (context) => const FriendsScreen(),
          Constants.friendRequestsScreen: (context) =>
              const FriendRequestScreen(),
          Constants.chatScreen: (context) => const ChatScreen(),
          Constants.groupSettingsScreen: (context) =>
              const GroupSettingsScreen(),
          Constants.groupInformationScreen: (context) =>
              const GroupInformationScreen(),
        },
      ),
    );
  }
}
