import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/providers/chat_provider.dart';
import 'package:privy_chat/streams/chats_stream.dart';
import 'package:privy_chat/streams/search_stream.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              // cupertinosearchbar
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                ),
                child: CupertinoSearchTextField(
                  placeholder: 'Search',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                  onChanged: (value) {
                    chatProvider.setSearchQuery(value);
                  },
                  onSuffixTap: () {
                    chatProvider.setSearchQuery('');
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              Expanded(
                child: chatProvider.searchQuery.isEmpty
                    ? ChatsStream(uid: uid)
                    : SearchStream(uid: uid),
              ),
            ],
          );
        },
      ),
    );
  }
}
