import 'package:flutter/material.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/providers/authentication_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:privy_chat/constants.dart';

class PendingRequestsScreen extends StatelessWidget {
  final String groupId;

  const PendingRequestsScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Join Requests'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(Constants.groups)
            .doc(groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No pending requests'));
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> awaitingApprovalUIDs = 
              List<String>.from(groupData[Constants.awaitingApprovalUIDs] ?? []);

          if (awaitingApprovalUIDs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          return ListView.builder(
            itemCount: awaitingApprovalUIDs.length,
            itemBuilder: (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(Constants.users)
                    .doc(awaitingApprovalUIDs[index])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final user = UserModel.fromMap(userData);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.image),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _handleRequest(
                            context,
                            user.uid,
                            true,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _handleRequest(
                            context,
                            user.uid,
                            false,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleRequest(BuildContext context, String userId, bool isApproved) async {
    try {
      if (isApproved) {
        await context.read<GroupProvider>().approveJoinRequest(
          groupId: groupId,
          userId: userId,
        );
      } else {
        await context.read<GroupProvider>().rejectJoinRequest(
          groupId: groupId,
          userId: userId,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}