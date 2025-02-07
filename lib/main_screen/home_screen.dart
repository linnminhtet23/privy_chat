import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/main_screen/create_group_screen.dart';
import 'package:privy_chat/main_screen/my_chats_screen.dart';
import 'package:privy_chat/main_screen/groups_screen.dart';
import 'package:privy_chat/main_screen/people_screen.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/push_notification/navigation_controller.dart';
import 'package:privy_chat/push_notification/notification_services.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:provider/provider.dart';
import 'package:privy_chat/providers/chat_provider.dart';


import '../providers/authentication_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final PageController pageController = PageController(initialPage: 0);
  int currentIndex = 0;
  bool _appBadgeSupported = false;
  // Example badge counts
  int chatBadgeCount = 3;
  int groupBadgeCount = 3;
  int peopleBadgeCount = 0;

  final List<Widget> pages = const [
    MyChatsScreen(),
    GroupsScreen(),
    PeopleScreen(),
  ];

  StreamSubscription<int>? _chatBadgeSubscription;
  StreamSubscription<int>? _groupBadgeSubscription;

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    initPlatformState();
    requestNotificationPermissions();
    NotificationServices.createNotificationChannelAndInitialize();
    initCloudMessaging();


    final authProvider = context.read<AuthenticationProvider>();
    final userId = authProvider.userModel?.uid;
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  initPlatformState() async {
    bool appBadgeSupported = false;

    try {
      bool res = await FlutterAppBadger.isAppBadgeSupported();
      if (res) {
        appBadgeSupported = true;
      } else {
        appBadgeSupported = false;
      }
    } on PlatformException {
      log('Failed');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _appBadgeSupported = appBadgeSupported;
    });
    // remove app badge if supported
    if (_appBadgeSupported) {
      FlutterAppBadger.removeBadge();
    }
  }

  // request notification permissions
  void requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true,
      );
    }

    NotificationSettings notificationSettings =
        await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      print('User granted permission ${notificationSettings.authorizationStatus}');
    } else if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // initialize cloud messaging
  void initCloudMessaging() async {
    // make sure widget is initialized before initializing cloud messaging
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. generate a new token
      await context.read<AuthenticationProvider>().generateNewToken();
      print("Remote Message");
      // 2. initialize firebase messaging
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Firebase Messaging Listener Triggered");

        if (message.notification != null) {
          // update app badge
          if (_appBadgeSupported) {
            FlutterAppBadger.updateBadgeCount(1);
          }
          NotificationServices.displayNotification(message);
        }
      });

      // 3. setup onMessage handler
      setupInteractedMessage();
    });
  }

  // It is assumed that all messages contain a data field with the key 'type'
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    navigationControler(context: context, message: message);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // user comes back to the app
        // update user status to online
        context.read<AuthenticationProvider>().updateUserStatus(
              value: true,
            );
        // remove the badge if the app is resumed
        FlutterAppBadger.removeBadge();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // app is inactive, paused, detached or hidden
        // update user status to offline
        context.read<AuthenticationProvider>().updateUserStatus(
              value: false,
            );
        break;
      default:
        // handle other states
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    return Scaffold(
        appBar: AppBar(
          title: const Text('Privy Chat'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: authProvider.userModel != null
                  ? userImageWidget(
                imageUrl: authProvider.userModel!.image,
                radius: 20,
                onTap: () {
                  // navigate to user profile with uis as arguments
                  Navigator.pushNamed(
                    context,
                    Constants.profileScreen,
                    arguments: authProvider.userModel!.uid,
                  );
                },
              )  : IconButton(
                icon: const Icon(CupertinoIcons.person),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("User not logged in."),
                    ),
                  );
                },
              ),
            )
          ],
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          children: pages,
        ),
        floatingActionButton: currentIndex == 1
            ? FloatingActionButton(
                onPressed: () {
                  context
                      .read<GroupProvider>()
                      .clearGroupMembersList()
                      .whenComplete(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateGroupScreen(),
                      ),
                    );
                  });
                },
                child: const Icon(CupertinoIcons.add),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          // items: const [
          //   BottomNavigationBarItem(
          //     icon: Icon(CupertinoIcons.chat_bubble_2),
          //     label: 'Chats',
          //   ),
          //   BottomNavigationBarItem(
          //     icon: Icon(CupertinoIcons.group),
          //     label: 'Groups',
          //   ),
          //   BottomNavigationBarItem(
          //     icon: Icon(CupertinoIcons.globe),
          //     label: 'People',
          //   ),
          // ],
          items: [
            BottomNavigationBarItem(
              icon: _buildBadge(
                icon: CupertinoIcons.chat_bubble_2,
                badgeCount: chatBadgeCount,
              ),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: _buildBadge(
                icon: CupertinoIcons.group,
                badgeCount: groupBadgeCount,
              ),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: _buildBadge(
                icon: CupertinoIcons.globe,
                badgeCount: peopleBadgeCount,
              ),
              label: 'People',
            ),
          ],
          currentIndex: currentIndex,
          onTap: (index) {
            // animate to the page
            pageController.animateToPage(index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn);
            setState(() {
              currentIndex = index;
            });
          },
        ));
  }
  Widget _buildBadge({required IconData icon, required int badgeCount}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 24),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
