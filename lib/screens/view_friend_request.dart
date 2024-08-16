import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/providers/auth_provider.dart';
import 'package:privy_chat/providers/user_provider.dart';

class ViewFriendRequest extends StatefulWidget {
  const ViewFriendRequest({super.key});

  @override
  State<ViewFriendRequest> createState() => _ViewFriendRequestState();
}

class _ViewFriendRequestState extends State<ViewFriendRequest> {
  List<Map<String, dynamic>> _friendRequests = [];

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  void _loadFriendRequests() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userModel!.uid;

    final requests = await userProvider.getFriendRequests(userId);
    setState(() {
      _friendRequests = requests;
    });
  }

  Future<UserModel> _getUserModel(String userId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return await userProvider.getUserById(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: ListView.builder(
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          final requestId = request['id'];
          final senderId = request['data']['senderId'];

          return FutureBuilder<UserModel>(
            future: _getUserModel(senderId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final sender = snapshot.data!;

              return ListTile(
                title: Text(sender.username),
                subtitle: Text(sender.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        await Provider.of<UserProvider>(context, listen: false)
                            .respondToFriendRequest(requestId, 'accept');
                        setState(() {
                          _friendRequests.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Accepted friend request from ${sender.username}')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        await Provider.of<UserProvider>(context, listen: false)
                            .respondToFriendRequest(requestId, 'reject');
                        setState(() {
                          _friendRequests.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Rejected friend request from ${sender.username}')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}