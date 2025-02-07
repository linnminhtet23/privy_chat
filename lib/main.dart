
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

void main() async {
    // Generate RSA key pair
  // final rsaKeyPair = generateRSAKeyPair();
  // final publicKey = rsaKeyPair.publicKey;
  // final privateKey = rsaKeyPair.privateKey;

  // final encodePublicKey = encodePublicKeyToPem(publicKey);
  //   final encodePrivateKey = encodePrivateKeyToPem(privateKey);

  // final decodePublicKey = decodePublicKeyFromPem(encodePublicKey);
  //   final decodePrivateKey = decodePrivateKeyFromPem(encodePrivateKey);
  //   print("Encode Public Key: $encodePublicKey, Encode Private Key: $encodePrivateKey");

  //   print("Decoded Public Key: $decodePublicKey, Decode Private Key: $decodePrivateKey");

  // // Encrypt a message using hybrid encryption
  // final plaintext = "Hello World!0000";
  // final encryptedData = hybridEncrypt(plaintext, decodePublicKey);
  // print("Encrypted Data: $encryptedData");

  // // Decrypt the message using hybrid decryption
  // final decryptedData = hybridDecrypt(encryptedData, decodePrivateKey);
  // print("Decrypted Data: $decryptedData");

  WidgetsFlutterBinding.ensureInitialized();
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
        initialRoute: Constants.landingScreen,
        routes: {
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
