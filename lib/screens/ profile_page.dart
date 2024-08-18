import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "John Doe";
  String userEmail = "john.doe@example.com";
  String profileImageUrl = "https://www.example.com/profile.jpg"; // Placeholder URL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the edit profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              userEmail,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Log out logic
                // e.g., FirebaseAuth.instance.signOut();
              },
              child: const Text("Log Out"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: Center(
        child: const Text("Edit profile form goes here."),
      ),
    );
  }
}
