import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/providers/auth_provider.dart';
import 'package:privy_chat/providers/user_provider.dart';

class SearchUser extends StatefulWidget {
  const SearchUser({super.key});

  @override
  State<SearchUser> createState() => _SearchUserState();
}

class _SearchUserState extends State<SearchUser> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  Map<String, String> _friendRequestStatus = {};

  void searchUsers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final results = await userProvider.searchUsers(_searchController.text);
    setState(() {
      _searchResults = results;
    });

    // Fetch the status of friend requests
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    for (var user in _searchResults) {
      final status = await _getFriendRequestStatus(authProvider.userModel!.uid, user.uid);
      setState(() {
        _friendRequestStatus[user.uid] = status;
      });
    }
  }

  Future<String> _getFriendRequestStatus(String userId, String friendId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final friendRequests = await userProvider.getFriendRequests(userId);
    for (var request in friendRequests) {
      if (request['data']['senderId'] == friendId || request['data']['receiverId'] == friendId) {
        return request['data']['status'];
      }
    }
    return 'none';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Username',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchUsers,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final status = _friendRequestStatus[user.uid] ?? 'none';

                  return ListTile(
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    trailing: status == 'pending'
                        ? const Text('Request Sent')
                        : status == 'accepted'
                            ? const Text('Friends')
                            : IconButton(
                                icon: const Icon(Icons.person_add),
                                onPressed: () async {
                                  final currentUserId = authProvider.userModel!.uid;
                                  await userProvider.sendFriendRequest(currentUserId, user.uid);
                                  setState(() {
                                    _friendRequestStatus[user.uid] = 'pending';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Friend request sent to ${user.username}')),
                                  );
                                },
                              ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
