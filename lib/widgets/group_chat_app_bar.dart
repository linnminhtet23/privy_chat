import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/models/group_model.dart';
import 'package:privy_chat/providers/authentication_provider.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:privy_chat/widgets/group_members.dart';
import 'package:provider/provider.dart';

class GroupChatAppBar extends StatefulWidget {
  const GroupChatAppBar({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupChatAppBar> createState() => _GroupChatAppBarState();
}

class _GroupChatAppBarState extends State<GroupChatAppBar> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          context.read<GroupProvider>().groupStream(groupId: widget.groupId),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupModel =
            GroupModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

        // Check if current user is admin
        final currentUserUID = context.read<AuthenticationProvider>().userModel!.uid;
        final isAdmin = groupModel.adminsUIDs.contains(currentUserUID);
        final awaitingApprovalCount = groupModel.awaitingApprovalUIDs.length;

        return GestureDetector(
          onTap: () {
            // navigate to group information screen
            context
                .read<GroupProvider>()
                .updateGroupMembersList().whenComplete(() {
              Navigator.pushNamed(context, Constants.groupInformationScreen);
            });
                // .then((value) => GlobalMethods.navigateToScreen(
                //     context: context,
                //     routeName: Constants.groupInformationScreen));
          },
          child: Row(
            children: [
              Stack(
                children: [
                  userImageWidget(
                imageUrl: groupModel.groupImage,
                radius: 20,
                onTap: () {
                  // navigate to group settings screen
                },
              ),
                  if (isAdmin && awaitingApprovalCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          awaitingApprovalCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupModel.groupName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${groupModel.membersUIDs.length} members',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
