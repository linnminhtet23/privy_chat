import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/providers/authentication_provider.dart';
import 'package:privy_chat/widgets/botton_chat_field.dart';
import 'package:privy_chat/widgets/chat_app_bar.dart';
import 'package:privy_chat/widgets/chat_list.dart';
import 'package:privy_chat/widgets/group_chat_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:privy_chat/utilities/assets_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // get arguments passed from previous screen
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    // get the contactUID from the arguments with default empty string
    final contactUID = arguments[Constants.contactUID] as String? ?? '';
    // get the contactName from the arguments with default empty string
    final contactName = arguments[Constants.contactName] as String? ?? '';
    // get the contactImage from the arguments with default empty string
    final contactImage = arguments[Constants.contactImage] as String? ?? '';
    // get the groupId from the arguments with default empty string
    final groupId = arguments[Constants.groupId] as String? ?? '';
    // check if the groupId is empty - then its a chat with a friend else its a group chat
    final isGroupChat = groupId.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: // get appBar color from theme
            Theme.of(context).appBarTheme.backgroundColor,
        title: isGroupChat
            ? GroupChatAppBar(groupId: groupId)
            : ChatAppBar(contactUID: contactUID),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ChatList(
                contactUID: contactUID,
                groupId: groupId,
              ),
            ),
           
                 StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(Constants.users)
                      .doc(contactUID)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const SizedBox.shrink();
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final isTyping = data['isTyping'] ?? false;
                    final typingInChatRoom = data['typingInChatRoom'];
                    
                    // Only show typing indicator when the contact is typing in this chat
                    if (isTyping && typingInChatRoom == context.read<AuthenticationProvider>().userModel!.uid) {
                       
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 60,
                              width: 60,
                              child: Lottie.asset(
                                AssetsMenager.typingIndicator,
                                fit: BoxFit.contain,
                              ),
                            )
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
           
            BottomChatField(
              contactUID: contactUID,
              contactName: contactName,
              contactImage: contactImage,
              groupId: groupId,
            ),
          ],
        ),
      ),
    );
  }
}
