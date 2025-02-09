import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/widgets/botton_chat_field.dart';
import 'package:privy_chat/widgets/chat_app_bar.dart';
import 'package:privy_chat/widgets/chat_list.dart';
import 'package:privy_chat/widgets/group_chat_app_bar.dart';

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
