import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/providers/authentication_provider.dart';
import 'package:privy_chat/push_notification/notification_services.dart';
import 'package:privy_chat/widgets/botton_chat_field.dart';
import 'package:privy_chat/widgets/chat_app_bar.dart';
import 'package:privy_chat/widgets/chat_list.dart';
import 'package:privy_chat/widgets/group_chat_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:privy_chat/utilities/assets_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // get arguments passed from previous screen
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
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
    final currentUserUID =
        context.read<AuthenticationProvider>().userModel!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: // get appBar color from theme
            Theme.of(context).appBarTheme.backgroundColor,
        title: isGroupChat
            ? GroupChatAppBar(groupId: groupId)
            : ChatAppBar(contactUID: contactUID),
      ),
      body: isGroupChat
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(Constants.groups)
                  .doc(groupId)
                  .snapshots(),
              builder: (context, snapshot) {
                // if (snapshot.hasError) {
                //   return const Center(child: Text('Something went wrong'));
                // }

                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const Center(child: CircularProgressIndicator());
                // }

                // if (!snapshot.hasData || !snapshot.data!.exists) {
                //   return const Center(child: Text('Group not found'));
                // }

                final groupData = snapshot.data!.data() as Map<String, dynamic>;
                
                final isPrivate = groupData['isPrivate'] ?? false;
                final membersUIDs =
                    List<String>.from(groupData['membersUIDs'] ?? []);
                final awaitingApprovalUIDs =
                    List<String>.from(groupData['awaitingApprovalUIDs'] ?? []);

                if (!membersUIDs.contains(currentUserUID)) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isPrivate
                              ? const Icon(
                                  Icons.lock,
                                  size: 64,
                                  color: Colors.grey,
                                )
                              : const Icon(
                                  Icons.public,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                          const SizedBox(height: 16),
                          Text(
                            isPrivate
                                ? 'This is a private group'
                                : 'This is a public group',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You need to be a member to view and send messages',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (!awaitingApprovalUIDs.contains(currentUserUID))
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (groupData['requestToJoing']) {
                                    // Get current user data
                                    final currentUserDoc =
                                        await FirebaseFirestore.instance
                                            .collection(Constants.users)
                                            .doc(currentUserUID)
                                            .get();
                                    final currentUserData =
                                        currentUserDoc.data();

                                    // Add user to awaiting approval list
                                    await FirebaseFirestore.instance
                                        .collection(Constants.groups)
                                        .doc(groupId)
                                        .update({
                                      'awaitingApprovalUIDs':
                                          FieldValue.arrayUnion(
                                              [currentUserUID])
                                    });

                                    // Get all admin UIDs
                                    final List<String> adminUIDs =
                                        List<String>.from(
                                            groupData['adminsUIDs'] ?? []);

                                    // Send notification to each admin
                                    for (final adminUID in adminUIDs) {
                                      final adminDoc = await FirebaseFirestore
                                          .instance
                                          .collection(Constants.users)
                                          .doc(adminUID)
                                          .get();

                                      if (adminDoc.exists) {
                                        final adminData = adminDoc.data();
                                        if (adminData != null &&
                                            adminData[Constants.token] !=
                                                null) {
                                          await NotificationServices
                                              .sendNotification(
                                            token: adminData[Constants.token],
                                            title: 'New Join Request',
                                            body:
                                                '${currentUserData?[Constants.name] ?? 'Someone'} wants to join ${groupData['groupName']}',
                                            data: {
                                              'notificationType': Constants
                                                  .groupChatNotification,
                                              // 'senderImage': currentUserData?[Constants.image] ?? '',
                                              // Constants.uid: currentUserUID,
                                              'groupId': groupId
                                            },
                                          );
                                        }
                                      }
                                    }
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection(Constants.groups)
                                        .doc(groupId)
                                        .update({
                                      'membersUIDs': FieldValue.arrayUnion(
                                          [currentUserUID])
                                    });
                                  }
                                } catch (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to process request: ${error.toString()}')));
                                }
                              },
                              child: Text(groupData['requestToJoing']
                                  ? 'Request to Join'
                                  : 'Join Group'),
                            )
                          else
                            const Text(
                              'Join request pending approval',
                              style: TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ChatList(
                          contactUID: contactUID,
                          groupId: groupId,
                        ),
                      ),

                      // Typing indicator for group chat
                      if (isGroupChat)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(Constants.groups)
                              .doc(groupId)
                              .collection('typing')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final typingUsers = snapshot.data!.docs
                                .where((doc) => doc['isTyping'] == true)
                                .where((doc) => doc.id != currentUserUID)
                                .toList();

                            if (typingUsers.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            // Get user names for typing users
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection(Constants.users)
                                  .where(FieldPath.documentId,
                                      whereIn: typingUsers
                                          .map((doc) => doc.id)
                                          .toList())
                                  .snapshots(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                final userDocs = userSnapshot.data!.docs;
                                final typingNames = userDocs
                                    .map((doc) => doc.get('name') as String)
                                    .toList();

                                String typingText;
                                if (typingNames.length == 1) {
                                  typingText = '${typingNames[0]} is typing...';
                                } else if (typingNames.length == 2) {
                                  typingText =
                                      '${typingNames[0]} and ${typingNames[1]} are typing...';
                                } else {
                                  typingText =
                                      '${typingNames.length} people are typing...';
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        height: 60,
                                        width: 60,
                                        child: Lottie.asset(
                                          AssetsMenager.typingIndicator,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          typingText,
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        )
                      else
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(Constants.users)
                              .doc(contactUID)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const SizedBox.shrink();
                            }

                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const SizedBox.shrink();
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final isTyping = data['isTyping'] ?? false;
                            final typingInChatRoom = data['typingInChatRoom'];

                            if (isTyping &&
                                typingInChatRoom == currentUserUID) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: Lottie.asset(
                                        AssetsMenager.typingIndicator,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Text(
                                      '${data['name']} is typing...',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      BottomChatField(
                        contactUID: contactUID,
                        contactName: contactName,
                        contactImage: contactImage,
                        groupId: groupId,
                      ),
                    ],
                  ),
                );
              },
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: ChatList(
                      contactUID: contactUID,
                      groupId: groupId,
                    ),
                  ),
                  // Typing indicator for group chat
                  if (isGroupChat)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection(Constants.groups)
                          .doc(groupId)
                          .collection('typing')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final typingUsers = snapshot.data!.docs
                            .where((doc) => doc['isTyping'] == true)
                            .where((doc) => doc.id != currentUserUID)
                            .toList();

                        if (typingUsers.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: Lottie.asset(
                                  AssetsMenager.typingIndicator,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Text(
                                typingUsers.length == 1
                                    ? 'Someone is typing...'
                                    : '${typingUsers.length} people are typing...',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection(Constants.users)
                          .doc(contactUID)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const SizedBox.shrink();
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final isTyping = data['isTyping'] ?? false;
                        final typingInChatRoom = data['typingInChatRoom'];

                        if (isTyping && typingInChatRoom == currentUserUID) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: Lottie.asset(
                                    AssetsMenager.typingIndicator,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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

