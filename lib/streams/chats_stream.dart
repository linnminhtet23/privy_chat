import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/models/last_message_model.dart';
import 'package:privy_chat/providers/chat_provider.dart';
import 'package:privy_chat/widgets/chat_widget.dart';
import 'package:provider/provider.dart';

class ChatsStream extends StatelessWidget {
  const ChatsStream({
    super.key,
    required this.uid,
    this.groupId = '',
  });

  final String uid;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LastMessageModel>>(
      stream: context.read<ChatProvider>().getChatsListStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasData) {
          final chatsList = snapshot.data!;
          return ListView.builder(
            itemCount: chatsList.length,
            itemBuilder: (context, index) {
              final chat = chatsList[index];
              print({"chatlist": chat.contactName});

              return ChatWidget(
                chat: chat,
                isGroup: false,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Constants.chatScreen,
                    arguments: {
                      Constants.contactUID: chat.contactUID,
                      Constants.contactName: chat.contactName,
                      Constants.contactImage: chat.contactImage,
                      Constants.groupId: '',
                    },
                  );
                },
              );
            },
          );
        }
        return const Center(
          child: Text('No chats yet'),
        );
      },
    );
  }
}
