import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/enums/enums.dart';
import 'package:privy_chat/widgets/my_app_bar.dart';
import 'package:privy_chat/widgets/friends_list.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: const Text('Friends'),
        onPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // cupertinosearchbar
            CupertinoSearchTextField(
              placeholder: 'Search',
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                print(value);
              },
              onSuffixTap: () {
                print('suffix tap');
                FocusScope.of(context).unfocus();
              },
            ),

            const Expanded(
                child: FriendsList(
              viewType: FriendViewType.friends,
            )),
          ],
        ),
      ),
    );
  }
}
