import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/enums/enums.dart';
import 'package:privy_chat/models/last_message_model.dart';
import 'package:privy_chat/models/message_model.dart';
import 'package:privy_chat/models/message_reply_model.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

import '../utils/encryption_utils.dart';

class ChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  MessageReplyModel? _messageReplyModel;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _searchQuery = '';

  // getters
  String get searchQuery => _searchQuery;

  bool get isLoading => _isLoading;
  MessageReplyModel? get messageReplyModel => _messageReplyModel;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setMessageReplyModel(MessageReplyModel? messageReply) {
    _messageReplyModel = messageReply;
    notifyListeners();
  }

  // firebase initialization
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// send text message to firestore
//   Future<void> sendTextMessage({
//     required UserModel sender,
//     required String contactUID,
//     required String contactName,
//     required String contactImage,
//     required String message,
//     required MessageEnum messageType,
//     required String groupId,
//     required Function onSucess,
//     required Function(String) onError,
//   }) async {
//     // set loading to true
//     setLoading(true);
//     try {
//       var messageId = const Uuid().v4();
//
//       // 1. check if its a message reply and add the replied message to the message
//       String repliedMessage = _messageReplyModel?.message ?? '';
//       String repliedTo = _messageReplyModel == null
//           ? ''
//           : _messageReplyModel!.isMe
//               ? 'You'
//               : _messageReplyModel!.senderName;
//       MessageEnum repliedMessageType =
//           _messageReplyModel?.messageType ?? MessageEnum.text;
//
//       // 2. update/set the messagemodel
//       final messageModel = MessageModel(
//         senderUID: sender.uid,
//         senderName: sender.name,
//         senderImage: sender.image,
//         contactUID: contactUID,
//         message: message,
//         messageType: messageType,
//         timeSent: DateTime.now(),
//         messageId: messageId,
//         isSeen: false,
//         repliedMessage: repliedMessage,
//         repliedTo: repliedTo,
//         repliedMessageType: repliedMessageType,
//         reactions: [],
//         isSeenBy: [sender.uid],
//         deletedBy: [],
//       );
//
//       // 3. check if its a group message and send to group else send to contact
//       if (groupId.isNotEmpty) {
//         // handle group message
//         await _firestore
//             .collection(Constants.groups)
//             .doc(groupId)
//             .collection(Constants.messages)
//             .doc(messageId)
//             .set(messageModel.toMap());
//
//         // update the last message fo the group
//         await _firestore.collection(Constants.groups).doc(groupId).update({
//           Constants.lastMessage: message,
//           Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
//           Constants.senderUID: sender.uid,
//           Constants.messageType: messageType.name,
//         });
//
//         // set loading to true
//         setLoading(false);
//         onSucess();
//         // set message reply model to null
//         setMessageReplyModel(null);
//       } else {
//         // handle contact message
//         await handleContactMessage(
//           messageModel: messageModel,
//           contactUID: contactUID,
//           contactName: contactName,
//           contactImage: contactImage,
//           onSucess: onSucess,
//           onError: onError,
//         );
//
//         // set message reply model to null
//         setMessageReplyModel(null);
//       }
//     } catch (e) {
//       // set loading to true
//       setLoading(false);
//       onError(e.toString());
//     }
//   }
  Future<void> sendEncryptedMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required String message,
    required MessageEnum messageType,
    required String groupId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    // Set loading to true
    setLoading(true);
    try {
      var messageId = const Uuid().v4();

      // Check if it's a message reply and add the replied message to the message
      String repliedMessage = _messageReplyModel?.message ?? '';
      String repliedTo = _messageReplyModel == null
          ? ''
          : _messageReplyModel!.isMe
          ? 'You'
          : _messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          _messageReplyModel?.messageType ?? MessageEnum.text;

      // Fetch the recipient's public key from Firestore
      final recipientData = await _firestore.collection('users').doc(contactUID).get();
      final recipientPublicKeyPem = recipientData.data()?['publicKey'];
      if (recipientPublicKeyPem == null) {
        throw Exception("Recipient public key not found.");
      }
      print("RSAPublicKey");

      final recipientPublicKey = EncryptionUtils.decodePublicKeyFromPem(recipientPublicKeyPem);

      // Encrypt the message using hybrid encryption
      final encryptedData = EncryptionUtils.hybridEncrypt(message, recipientPublicKey);
      print("encrypted data $encryptedData");
      // Create the encrypted message model
      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: encryptedData['cipherText'], // Store encrypted message
        messageType: messageType,
        timeSent: DateTime.now(),
        messageId: messageId,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        reactions: [],
        isSeenBy: [sender.uid],
        deletedBy: [],
        additionalData: {
          'encryptedAESKey': encryptedData['encryptedAESKey'],
          'iv': encryptedData['iv'],
        },
      );

       // 3. check if its a group message and send to group else send to contact
      if (groupId.isNotEmpty) {
        // handle group message
        await _firestore
            .collection(Constants.groups)
            .doc(groupId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(messageModel.toMap());

        // update the last message fo the group
        await _firestore.collection(Constants.groups).doc(groupId).update({
          Constants.lastMessage: message,
          Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constants.senderUID: sender.uid,
          Constants.messageType: messageType.name,
        });

        // set loading to true
        setLoading(false);
        onSuccess();
        // set message reply model to null
        setMessageReplyModel(null);
      } else {
        // handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSucess: onSuccess,
          onError: onError,
          additionalData: {
            'encryptedAESKey': encryptedData['encryptedAESKey'],
            'iv': encryptedData['iv'],
          },
        );

        // set message reply model to null
        setMessageReplyModel(null);
      }

      // Notify the UI about success
    } catch (e) {
      print(e);
      onError(e.toString());
    } finally {
      // Set loading to false
      setLoading(false);
    }
  }

  // send file message to firestore
  Future<void> sendFileMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required File file,
    required MessageEnum messageType,
    required String groupId,
    required Function onSucess,
    required Function(String) onError,
  }) async {
    // set loading to true
    setLoading(true);
    try {
      var messageId = const Uuid().v4();

      // 1. check if its a message reply and add the replied message to the message
      String repliedMessage = _messageReplyModel?.message ?? '';
      String repliedTo = _messageReplyModel == null
          ? ''
          : _messageReplyModel!.isMe
              ? 'You'
              : _messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          _messageReplyModel?.messageType ?? MessageEnum.text;

      // 2. upload file to firebase storage
      final ref =
          '${Constants.chatFiles}/${messageType.name}/${sender.uid}/$contactUID/$messageId';
      String fileUrl = await storeFileToStorage(file: file, reference: ref);

      // 3. update/set the messagemodel
      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: fileUrl,
        messageType: messageType,
        timeSent: DateTime.now(),
        messageId: messageId,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        reactions: [],
        isSeenBy: [sender.uid],
        deletedBy: [],
      );

      // 4. check if its a group message and send to group else send to contact
      if (groupId.isNotEmpty) {
        // handle group message
        // handle group message
        await _firestore
            .collection(Constants.groups)
            .doc(groupId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(messageModel.toMap());

        // update the last message fo the group
        await _firestore.collection(Constants.groups).doc(groupId).update({
          Constants.lastMessage: fileUrl,
          Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constants.senderUID: sender.uid,
          Constants.messageType: messageType.name,
        });

        // set loading to true
        setLoading(false);
        onSucess();
        // set message reply model to null
        setMessageReplyModel(null);
      } else {
        // handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSucess: onSucess,
          onError: onError,
        );

        // set message reply model to null
        setMessageReplyModel(null);
      }
    } catch (e) {
      // set loading to true
      setLoading(false);
      onError(e.toString());
    }
  }

  Future<void> handleContactMessage({
    required MessageModel messageModel,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required Function onSucess,
    required Function(String p1) onError,
     Map<String, dynamic>? additionalData,
  }) async {
    try {
      // 0. contact messageModel
      final contactMessageModel = messageModel.copyWith(
        userId: messageModel.senderUID,
      );

      // 1. initialize last message for the sender
      final senderLastMessage = LastMessageModel(
        senderUID: messageModel.senderUID,
        contactUID: contactUID,
        contactName: contactName,
        contactImage: contactImage,
        message: messageModel.message,
        messageType: messageModel.messageType,
        timeSent: messageModel.timeSent,
        isSeen: false,
          additionalData:additionalData
      );

      // 2. initialize last message for the contact
      final contactLastMessage = senderLastMessage.copyWith(
        contactUID: messageModel.senderUID,
        contactName: messageModel.senderName,
        contactImage: messageModel.senderImage,
          additionalData:additionalData

      );
      // 3. send message to sender firestore location
      await _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageModel.messageId)
          .set(messageModel.toMap());
      // 4. send message to contact firestore location
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID)
          .collection(Constants.messages)
          .doc(messageModel.messageId)
          .set(contactMessageModel.toMap());

      // 5. send the last message to sender firestore location
      await _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID)
          .set(senderLastMessage.toMap());

      // 6. send the last message to contact firestore location
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID)
          .set(contactLastMessage.toMap());

      // // run transaction
      // await _firestore.runTransaction((transaction) async {
      //   // 3. send message to sender firestore location
      //   transaction.set(
      //     _firestore
      //         .collection(Constants.users)
      //         .doc(messageModel.senderUID)
      //         .collection(Constants.chats)
      //         .doc(contactUID)
      //         .collection(Constants.messages)
      //         .doc(messageModel.messageId),
      //     messageModel.toMap(),
      //   );
      //   // 4. send message to contact firestore location
      //   transaction.set(
      //     _firestore
      //         .collection(Constants.users)
      //         .doc(contactUID)
      //         .collection(Constants.chats)
      //         .doc(messageModel.senderUID)
      //         .collection(Constants.messages)
      //         .doc(messageModel.messageId),
      //     contactMessageModel.toMap(),
      //   );
      //   // 5. send the last message to sender firestore location
      //   transaction.set(
      //     _firestore
      //         .collection(Constants.users)
      //         .doc(messageModel.senderUID)
      //         .collection(Constants.chats)
      //         .doc(contactUID),
      //     senderLastMessage.toMap(),
      //   );
      //   // 6. send the last message to contact firestore location
      //   transaction.set(
      //     _firestore
      //         .collection(Constants.users)
      //         .doc(contactUID)
      //         .collection(Constants.chats)
      //         .doc(messageModel.senderUID),
      //     contactLastMessage.toMap(),
      //   );
      // });

      // 7.call onSucess
      // set loading to false
      setLoading(false);
      onSucess();
    } on FirebaseException catch (e) {
      // set loading to false
      setLoading(false);
      onError(e.message ?? e.toString());
    } catch (e) {
      // set loading to false
      setLoading(false);
      onError(e.toString());
    }
  }

  // send reaction to message
  Future<void> sendReactionToMessage({
    required String senderUID,
    required String contactUID,
    required String messageId,
    required String reaction,
    required bool groupId,
  }) async {
    // set loading to true
    setLoading(true);
    // a reaction is saved as senderUID=reaction
    String reactionToAdd = '$senderUID=$reaction';

    try {
      // 1. check if its a group message
      if (groupId) {
        // 2. get the reaction list from firestore
        final messageData = await _firestore
            .collection(Constants.groups)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .get();

        // 3. add the meesaage data to messageModel
        final message = MessageModel.fromMap(messageData.data()!);

        // 4. check if the reaction list is empty
        if (message.reactions.isEmpty) {
          // 5. add the reaction to the message
          await _firestore
              .collection(Constants.groups)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
            Constants.reactions: FieldValue.arrayUnion([reactionToAdd])
          });
        } else {
          // 6. get UIDs list from reactions list
          final uids = message.reactions.map((e) => e.split('=')[0]).toList();

          // 7. check if the reaction is already added
          if (uids.contains(senderUID)) {
            // 8. get the index of the reaction
            final index = uids.indexOf(senderUID);
            // 9. replace the reaction
            message.reactions[index] = reactionToAdd;
          } else {
            // 10. add the reaction to the list
            message.reactions.add(reactionToAdd);
          }

          // 11. update the message
          await _firestore
              .collection(Constants.groups)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({Constants.reactions: message.reactions});
        }
      } else {
        // handle contact message
        // 2. get the reaction list from firestore
        final messageData = await _firestore
            .collection(Constants.users)
            .doc(senderUID)
            .collection(Constants.chats)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .get();

        // 3. add the meesaage data to messageModel
        final message = MessageModel.fromMap(messageData.data()!);

        // 4. check if the reaction list is empty
        if (message.reactions.isEmpty) {
          // 5. add the reaction to the message
          await _firestore
              .collection(Constants.users)
              .doc(senderUID)
              .collection(Constants.chats)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
            Constants.reactions: FieldValue.arrayUnion([reactionToAdd])
          });
        } else {
          // 6. get UIDs list from reactions list
          final uids = message.reactions.map((e) => e.split('=')[0]).toList();

          // 7. check if the reaction is already added
          if (uids.contains(senderUID)) {
            // 8. get the index of the reaction
            final index = uids.indexOf(senderUID);
            // 9. replace the reaction
            message.reactions[index] = reactionToAdd;
          } else {
            // 10. add the reaction to the list
            message.reactions.add(reactionToAdd);
          }

          // 11. update the message to sender firestore location
          await _firestore
              .collection(Constants.users)
              .doc(senderUID)
              .collection(Constants.chats)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({Constants.reactions: message.reactions});

          // 12. update the message to contact firestore location
          await _firestore
              .collection(Constants.users)
              .doc(contactUID)
              .collection(Constants.chats)
              .doc(senderUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({Constants.reactions: message.reactions});
        }
      }

      // set loading to false
      setLoading(false);
    } catch (e) {
      print(e.toString());
    }
  }

  // get chatsList stream
  // Stream<List<LastMessageModel>> getChatsListStream(String userId)  {
  //   if (userId == null || userId.isEmpty) {
  //     // Return an empty stream if userId is invalid
  //     return Stream.value([]);
  //   }
  //
  //   return _firestore
  //       .collection(Constants.users)
  //       .doc(userId)
  //       .collection(Constants.chats)
  //       .orderBy(Constants.timeSent, descending: true)
  //       .snapshots()
  //       .map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       // return LastMessageModel.fromMap(doc.data());
  //       print("document data ${doc.data()}");
  //        var lastMessage = LastMessageModel.fromMap(doc.data());
  //
  //
  //
  //     return lastMessage;
  //     }).toList();
  //   });
  // }
  Future<String?> _getUserPrivateKey(String userId) async {
    // Fetch the private key securely from Firestore or local secure storage
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['privateKey'];
  }
  Stream<List<LastMessageModel>> getChatsListStream(String userId) {
    if (userId.isEmpty) {
      // Return an empty stream if userId is invalid
      return Stream.value([]);
    }

    return _firestore
        .collection(Constants.users)
        .doc(userId)
        .collection(Constants.chats)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // Load the user's private key (stored securely on the device or Firestore)
      final privateKeyPem = await _getUserPrivateKey(userId);

      if (privateKeyPem == null) {
        throw Exception("User private key not found.");
      }

      try {
        final privateKey = EncryptionUtils.decodePrivateKeyFromPem(privateKeyPem);
        print("Private key successfully decoded: $privateKey");

        return snapshot.docs.map((doc) {
          try {
            var messageData = doc.data();
            var lastMessage = LastMessageModel.fromMap(messageData);
            print("before decryptedMessage ${messageData}");

            // Check if message contains additionalData for decryption
            if (messageData['additionalData'] != null) {
              final additionalData = messageData['additionalData'];
              // print("additionalData ${{
              //   'encryptedAESKey': additionalData['encryptedAESKey'],
              //   'cipherText': messageData['message'],
              //   'iv': additionalData['iv'],
              // }}");

              // Decrypt the message using hybrid decryption
              final decryptedMessage = EncryptionUtils.hybridDecrypt({
                'encryptedAESKey': additionalData['encryptedAESKey'],
                'cipherText': messageData['message'],
                'iv': additionalData['iv'],
              }, privateKey);

              // Update the last message with the decrypted message
              lastMessage = lastMessage.copyWith(
                  contactUID: lastMessage.contactUID,
                  contactName: lastMessage.contactName,
                  contactImage: lastMessage.contactImage,
                  message: decryptedMessage); // Update the message
            }

            return lastMessage;
          } catch (e) {
            print("Error decrypting message for document ${doc.id}: $e");
            return LastMessageModel.fromMap(doc.data()); // Return the unmodified message in case of error
          }
        }).toList();
      } catch (e) {
        print("Error decoding private key or during decryption: $e");
        rethrow; // Re-throw the error if it fails during key decoding or decryption
      }
    });
  }




  // stream messages from chat collection
  Stream<List<MessageModel>> getMessagesStream({
    required String userId,
    required String contactUID,
    required String isGroup,
  }) {
    // 1. check if its a group message
    if (isGroup.isNotEmpty) {
      // handle group message
      return _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data());
        }).toList();
      });
    } else {
      // handle contact message
      return _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data());
        }).toList();
      });
    }
  }

  // stream the unread messages for this user
  Stream<int> getUnreadMessagesStream({
    required String userId,
    required String contactUID,
    required bool isGroup,
  }) {
    // 1. check if its a group message
    if (isGroup) {
      // handle group message
      return _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .asyncMap((event) {
        int count = 0;
        for (var doc in event.docs) {
          final message = MessageModel.fromMap(doc.data());
          if (!message.isSeenBy.contains(userId)) {
            count++;
          }
        }
        return count;
      });
    } else {
      // handle contact message
      return _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .where(Constants.isSeen, isEqualTo: false)
          .where(Constants.senderUID, isNotEqualTo: userId)
          .snapshots()
          .map((event) => event.docs.length);
    }
  }

  // set message status
  Future<void> setMessageStatus({
  required String currentUserId,
  required String contactUID,
  required String messageId,
  required List<String> isSeenByList,
  required bool isGroupChat,
}) async {
  try {
    // Check if it's a group chat
    if (isGroupChat) {
      if (isSeenByList.contains(currentUserId)) {
        return;
      } else {
        // Add the current user to the seenByList in all messages
        var messageDoc = await _firestore
            .collection(Constants.groups)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .get();
        
        if (messageDoc.exists) {
          await _firestore
              .collection(Constants.groups)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageId)
              .update({
            Constants.isSeenBy: FieldValue.arrayUnion([currentUserId]),
          });
        } else {
          print("Message document not found for group chat.");
        }
      }
    } else {
      // Handle contact message
      var userMessageDoc = await _firestore
          .collection(Constants.users)
          .doc(currentUserId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageId)
          .get();

      if (userMessageDoc.exists) {
        // Update the current message as seen
        await _firestore
            .collection(Constants.users)
            .doc(currentUserId)
            .collection(Constants.chats)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .update({Constants.isSeen: true});

        // Update the contact message as seen
        await _firestore
            .collection(Constants.users)
            .doc(contactUID)
            .collection(Constants.chats)
            .doc(currentUserId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({Constants.isSeen: true});

        // Update the last message as seen for current user
        await _firestore
            .collection(Constants.users)
            .doc(currentUserId)
            .collection(Constants.chats)
            .doc(contactUID)
            .update({Constants.isSeen: true});

        // Update the last message as seen for contact
        await _firestore
            .collection(Constants.users)
            .doc(contactUID)
            .collection(Constants.chats)
            .doc(currentUserId)
            .update({Constants.isSeen: true});
      } else {
        print("Message document not found for contact.");
      }
    }
  } catch (e) {
    print("Exception $e");
  }
}


  // delete message
  Future<void> deleteMessage({
    required String currentUserId,
    required String contactUID,
    required String messageId,
    required String messageType,
    required bool isGroupChat,
    required bool deleteForEveryone,
  }) async {
    // set loading
    setLoading(true);

    // check if its group chat
    if (isGroupChat) {
      // handle group message
      await _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.deletedBy: FieldValue.arrayUnion([currentUserId])
      });

      // is is delete for everyone and message type is not text, we also dele the file from storage
      if (deleteForEveryone) {
        // get all group members uids and put them in deletedBy list
        final groupData =
            await _firestore.collection(Constants.groups).doc(contactUID).get();

        final List<String> groupMembers =
            List<String>.from(groupData.data()![Constants.membersUIDs]);

        // update the message as deleted for everyone
        await _firestore
            .collection(Constants.groups)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .update({Constants.deletedBy: FieldValue.arrayUnion(groupMembers)});

        if (messageType != MessageEnum.text.name) {
          // delete the file from storage
          await deleteFileFromStorage(
            currentUserId: currentUserId,
            contactUID: contactUID,
            messageId: messageId,
            messageType: messageType,
          );
        }
      }

      // set loading to false
      setLoading(false);
    } else {
      // handle contact message
      // 1. update the current message as deleted
      await _firestore
          .collection(Constants.users)
          .doc(currentUserId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.deletedBy: FieldValue.arrayUnion([currentUserId])
      });
      // 2. check if delete for everyone then return if false
      if (!deleteForEveryone) {
        // set loading to false
        setLoading(false);
        return;
      }

      // 3. update the contact message as deleted
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(currentUserId)
          .collection(Constants.messages)
          .doc(messageId)
          .update({
        Constants.deletedBy: FieldValue.arrayUnion([currentUserId])
      });

      // 4. delete the file from storage
      if (messageType != MessageEnum.text.name) {
        await deleteFileFromStorage(
          currentUserId: currentUserId,
          contactUID: contactUID,
          messageId: messageId,
          messageType: messageType,
        );
      }

      // set loading to false
      setLoading(false);
    }
  }

  Future<void> deleteFileFromStorage({
    required String currentUserId,
    required String contactUID,
    required String messageId,
    required String messageType,
  }) async {
    final firebaseStorage = FirebaseStorage.instance;
    // delete the file from storage
    await firebaseStorage
        .ref(
            '${Constants.chatFiles}/$messageType/$currentUserId/$contactUID/$messageId')
        .delete();
  }

  // stream the last message collection
  Stream<QuerySnapshot> getLastMessageStream({
    required String userId,
    required String groupId,
  }) {
    return groupId.isNotEmpty
        ? _firestore
            .collection(Constants.groups)
            .where(Constants.membersUIDs, arrayContains: userId)
            .snapshots()
        : _firestore
            .collection(Constants.users)
            .doc(userId)
            .collection(Constants.chats)
            .snapshots();
  }
}
