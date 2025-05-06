import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/main_screen/faq_screen.dart';
import 'package:privy_chat/main_screen/help_screen.dart';
import 'package:privy_chat/main_screen/privacy_security_screen.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:privy_chat/widgets/my_app_bar.dart';
import 'package:privy_chat/widgets/info_details_card.dart';
import 'package:privy_chat/widgets/settings_list_tile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/authentication_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isDarkMode = false;

  // get the saved theme mode
  void getThemeMode() async {
    // get the saved theme mode
    final savedThemeMode = await AdaptiveTheme.getThemeMode();
    // check if the saved theme mode is dark
    if (savedThemeMode == AdaptiveThemeMode.dark) {
      // set the isDarkMode to true
      setState(() {
        isDarkMode = true;
      });
    } else {
      // set the isDarkMode to false
      setState(() {
        isDarkMode = false;
      });
    }
  }

  @override
  void initState() {
    getThemeMode();
    super.initState();
  }

  Future<void> shareApp() async {
    const String appLink = 'https://drive.google.com/drive/u/1/folders/1QO7E5T_k8byy18BwONAyv6_94W0aXR4l'; // Replace with your app's actual link
    const String message = 'Check out PrivyChat - A secure messaging app for private conversations! Download now: ';
    
    try {
      await Share.share('$message$appLink');
    } catch (e) {
      debugPrint('Error sharing app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // get user data from arguments
    final uid = ModalRoute.of(context)!.settings.arguments as String;
    final authProvider = context.watch<AuthenticationProvider>();
    bool isMyProfile = uid == authProvider.uid;
    return authProvider.isLoading
        ? const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 20,
                  ),
                  Text('Saving Image, Please wait...')
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: MyAppBar(
              title: const Text('Profile'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            body: StreamBuilder(
              stream: context
                  .read<AuthenticationProvider>()
                  .userStream(userID: uid),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userModel = UserModel.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoDetailsCard(
                          userModel: userModel,
                        ),
                        const SizedBox(height: 10),
                        isMyProfile
                            ? Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      'Settings',
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Card(
                                  //   child: Column(
                                  //     children: [
                                  //       SettingsListTile(
                                  //         title: 'Account',
                                  //         icon: Icons.person,
                                  //         iconContainerColor: Colors.deepPurple,
                                  //         onTap: () {
                                  //           // navigate to account settings
                                  //         },
                                  //       ),
                                  //       SettingsListTile(
                                  //         title: 'My Media',
                                  //         icon: Icons.image,
                                  //         iconContainerColor: Colors.green,
                                  //         onTap: () {
                                  //           // navigate to account settings
                                  //         },
                                  //       ),
                                  //       SettingsListTile(
                                  //         title: 'Notifications',
                                  //         icon: Icons.notifications,
                                  //         iconContainerColor: Colors.red,
                                  //         onTap: () {
                                  //           // navigate to account settings
                                  //           OpenSettings
                                  //               .openAppNotificationSetting();
                                  //         },
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                  const SizedBox(height: 10),
                                  Card(
                                    child: Column(
                                      children: [
                                        SettingsListTile(
                                          title: 'Help',
                                          icon: Icons.help,
                                          iconContainerColor: Colors.yellow,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const HelpScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        SettingsListTile(
                                          title: 'Share',
                                          icon: Icons.share,
                                          iconContainerColor: Colors.blue,
                                          onTap: () {
                                            // navigate to account settings
                                            shareApp();
                                          },
                                        ),
                                        SettingsListTile(
                                          title: 'FAQ',
                                          icon: Icons.help,
                                          iconContainerColor: Colors.brown,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const FAQScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        // SettingsListTile(
                                        //   title: 'Privacy & Security',
                                        //   icon: Icons.privacy_tip,
                                        //   iconContainerColor: Colors.deepPurple,
                                        //   onTap: () {
                                        //     Navigator.push(
                                        //       context,
                                        //       MaterialPageRoute(
                                        //         builder: (context) => const PrivacySecurityScreen(),
                                        //       ),
                                        //     );
                                        //   },
                                        // ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Card(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.only(
                                        // added padding for the list tile
                                        left: 8.0,
                                        right: 8.0,
                                      ),
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            isDarkMode
                                                ? Icons.nightlight_round
                                                : Icons.wb_sunny_rounded,
                                            color: isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: const Text('Change theme'),
                                      trailing: Switch(
                                          value: isDarkMode,
                                          onChanged: (value) {
                                            // set the isDarkMode to the value
                                            setState(() {
                                              isDarkMode = value;
                                            });
                                            // check if the value is true
                                            if (value) {
                                              // set the theme mode to dark
                                              AdaptiveTheme.of(context)
                                                  .setDark();
                                            } else {
                                              // set the theme mode to light
                                              AdaptiveTheme.of(context)
                                                  .setLight();
                                            }
                                          }),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Card(
                                    child: Column(
                                      children: [
                                        SettingsListTile(
                                          title: 'Logout',
                                          icon: Icons.logout_outlined,
                                          iconContainerColor: Colors.red,
                                          onTap: () {
                                            showMyAnimatedDialog(
                                              context: context,
                                              title: 'Logout',
                                              content:
                                                  'Are you sure you want to logout?',
                                              textAction: 'Logout',
                                              onActionTap:
                                                  (value, updatedText) {
                                                if (value) {
                                                  // logout
                                                  context
                                                      .read<
                                                          AuthenticationProvider>()
                                                      .logout()
                                                      .whenComplete(() {
                                                    Navigator.pop(context);
                                                    Navigator
                                                        .pushNamedAndRemoveUntil(
                                                      context,
                                                      Constants.loginScreen,
                                                      (route) => false,
                                                    );
                                                  });
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}
