import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/models/group_model.dart';
import 'package:privy_chat/models/last_message_model.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:privy_chat/widgets/unread_message_counter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../providers/authentication_provider.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({
    super.key,
    this.chat,
    this.group,
    required this.isGroup,
    required this.onTap,
  });

  final LastMessageModel? chat;
  final GroupModel? group;
  final bool isGroup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    // get the last message
    final lastMessage = chat != null ? chat!.message : group!.lastMessage;
    // get the senderUID
    final senderUID = chat != null ? chat!.senderUID : group!.senderUID;

    // get the date and time
    final timeSent = chat != null ? chat!.timeSent : group!.timeSent;
    final dateTime = formatDate(timeSent, [hh, ':', nn, ' ', am]);

    // get the image url
    final imageUrl = chat != null ? chat!.contactImage : group!.groupImage;

    // get the name
    final name = chat != null ? chat!.contactName : group!.groupName;

    // get the contactUID
    final contactUID = chat != null ? chat!.contactUID : group!.groupId;
    // get the messageType
    final messageType = chat != null ? chat!.messageType : group!.messageType;
    return ListTile(
      leading: Stack(
        children: [
          userImageWidget(
            imageUrl: imageUrl,
            radius: 40,
            onTap: () {},
          ),
          isGroup ? SizedBox.shrink() : StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(contactUID)
                .snapshots(),
            builder: (context, snapshot) {
              final isOnline = snapshot.hasData && snapshot.data!.exists
                  ? snapshot.data!.get('isOnline') ?? false
                  : false;
              return Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.green : Colors.grey,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: !isGroup ? StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(contactUID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            // final isTyping = snapshot.data!.get('isTyping') ?? false;
            // final typingInChatRoom = snapshot.data!.get('typingInChatRoom') ?? '';
            // if (isTyping && typingInChatRoom == uid) {
            //   return Row(
            //     children: [
            //       SizedBox(
            //         height: 32,
            //         width: 32,
            //         child: Lottie.asset(
            //           AssetsMenager.typingIndicator,
            //           fit: BoxFit.contain,
            //         ),
            //       ),
            //     ],
            //   );
            // }
            return Row(
              children: [
                // Container(
                //   width: 8,
                //   height: 8,
                //   decoration: BoxDecoration(
                //     shape: BoxShape.circle,
                //     color: isOnline ? Colors.green : Colors.grey,
                //   ),
                // ),
                const SizedBox(width: 5),
                uid == senderUID
                    ? const Text(
                        'You:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    : const SizedBox(),
                const SizedBox(width: 5),
                messageToShow(
                  type: messageType,
                  message: lastMessage,
                ),
              ],
            );
          }
          return Row(
            children: [
              uid == senderUID
                  ? const Text(
                      'You:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  : const SizedBox(),
              const SizedBox(width: 5),
              messageToShow(
                type: messageType,
                message: lastMessage,
              ),
            ],
          );
        },
      ) : Row(
        children: [
          uid == senderUID
              ? Text(
    'You:',
    style: TextStyle(fontWeight: FontWeight.bold),
    overflow: TextOverflow.ellipsis,
  )
              : const SizedBox(),
          const SizedBox(width: 5),
          messageToShow(
            type: messageType,
            message: lastMessage,
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dateTime),
            UnreadMessageCounter(
              uid: uid,
              contactUID: contactUID,
              isGroup: isGroup,
            )
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}