import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_flutter_chat/providers/auth_provider.dart';
import 'package:secure_flutter_chat/screens/login.dart';
import 'package:secure_flutter_chat/screens/search_user.dart';
import 'package:secure_flutter_chat/screens/view_friend_request.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authProvider.userModel != null) ...[
              Text(
                'Welcome, ${authProvider.userModel!.username}!',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: () async {
                await authProvider.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
              child: const Text('Logout'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchUser()),
                );
              },
              child: const Text('Search Users'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ViewFriendRequest()),
                );
              },
              child: const Text('Friend Requests'),
            ),
          ],
        ),
      ),
    );
  }
}
