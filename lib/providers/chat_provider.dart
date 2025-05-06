import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/enums/enums.dart';
import 'package:privy_chat/models/last_message_model.dart';
import 'package:privy_chat/models/message_model.dart';
import 'package:privy_chat/models/message_reply_model.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/push_notification/notification_services.dart';
import 'package:privy_chat/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

import '../utils/encryptionutilsnewapproach.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  MessageReplyModel? _messageReplyModel;
  Timer? _typingTimer;
  static const _typingDuration = Duration(milliseconds: 1000);

  String _searchQuery = '';

  // getters
  String get searchQuery => _searchQuery;

  bool get isLoading => _isLoading;
  MessageReplyModel? get messageReplyModel => _messageReplyModel;
  bool _isTyping = false;
  String _typingUserId = '';

  bool get isTyping => _isTyping;
  String get typingUserId => _typingUserId;

  // Update typing status for group chat
  Future<void> updateGroupTypingStatus({
    required String groupId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      if (_typingTimer?.isActive ?? false) {
        _typingTimer!.cancel();
      }

      // Update typing status in Firestore
      await _firestore
          .collection(Constants.groups)
          .doc(groupId)
          .collection('typing')
          .doc(userId)
          .set({
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (isTyping) {
        // Start a timer to automatically set typing to false after duration
        _typingTimer = Timer(_typingDuration, () async {
          await _firestore
              .collection(Constants.groups)
              .doc(groupId)
              .collection('typing')
              .doc(userId)
              .delete();
        });
      }

      // Update local state
      _isTyping = isTyping;
      _typingUserId = userId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating group typing status: $e');
    }
  }


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

  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    await NotificationServices.sendNotification(
      token: token,
      title: title,
      body: body,
      data: data,
    );
  }

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


      MessageModel messageModel;
      if (groupId.isNotEmpty) {
        // Fetch group public and private key
        final groupData = await _firestore.collection('groups').doc(groupId).get();
        final groupPublicKeyPEM = groupData.data()?['publicKey'];

        if (groupPublicKeyPEM == null) {
          throw Exception("Group public key not found.");
        }

        final groupPublicKey = decodePublicKeyFromPem(groupPublicKeyPEM);

        // Encrypt the message using the group's public key
        final encryptedGroupDataString = hybridEncrypt(message, groupPublicKey);
        final encryptedGroupData = jsonDecode(encryptedGroupDataString);

        Map<String, dynamic> tempRepliedMessage = {};
        Map<String, dynamic> tempRepliedAESKey = {};

        if (repliedMessage.isNotEmpty && repliedTo.isNotEmpty) {
          final encryptedGroupRepliedString = hybridEncrypt(repliedMessage, groupPublicKey);
          final encryptedGroupReplied = jsonDecode(encryptedGroupRepliedString);

          tempRepliedMessage = {
            groupId: encryptedGroupReplied['aesEncryptedData'],
          };
          tempRepliedAESKey = {
            groupId: encryptedGroupReplied['aesKeyEncrypted'],
          };
        }

        // Create the encrypted message model for the group
        messageModel = MessageModel(
          senderUID: sender.uid,
          senderName: sender.name,
          senderImage: sender.image,
          contactUID: "", // Empty for group messages
          message: '',
          tempMessage: {
            groupId: encryptedGroupData['aesEncryptedData'],
          },
          messageType: messageType,
          timeSent: DateTime.now(),
          messageId: messageId,
          isSeen: false,
          repliedMessage: '',
          tempRepliedMessage: tempRepliedMessage,
          repliedTo: repliedTo,
          repliedMessageType: repliedMessageType,
          reactions: [],
          isSeenBy: [sender.uid],
          deletedBy: [],
          aesKeyEncrypted: {
            groupId: encryptedGroupData['aesKeyEncrypted'],
          },
          aesKeyMessageReplied: tempRepliedAESKey,
        );
      } else {
        // Fetch the recipient's public key
        final recipientData = await _firestore.collection('users').doc(contactUID).get();
        final recipientPublicKeyPEM = recipientData.data()?['publicKey'];
        final senderPublicKeyPEM = sender.publicKey;

        if (recipientPublicKeyPEM == null || senderPublicKeyPEM == null) {
          throw Exception("Public keys not found.");
        }

        final recipientPublicKey = decodePublicKeyFromPem(recipientPublicKeyPEM);
        final senderPublicKey = decodePublicKeyFromPem(senderPublicKeyPEM);

        // Encrypt the message for both sender and recipient
        final encryptedReceiverDataString = hybridEncrypt(message, recipientPublicKey);
        final encryptedSenderDataString = hybridEncrypt(message, senderPublicKey);

        final encryptedReceiverData = jsonDecode(encryptedReceiverDataString);
        final encryptedSenderData = jsonDecode(encryptedSenderDataString);

        Map<String, dynamic> tempRepliedMessage = {};
        Map<String, dynamic> tempRepliedAESKey = {};

        if (repliedMessage.isNotEmpty && repliedTo.isNotEmpty) {
          final encryptedReceiverRepliedString = hybridEncrypt(repliedMessage, recipientPublicKey);
          final encryptedSenderRepliedString = hybridEncrypt(repliedMessage, senderPublicKey);

          final encryptedReceiverReplied = jsonDecode(encryptedReceiverRepliedString);
          final encryptedSenderReplied = jsonDecode(encryptedSenderRepliedString);

          tempRepliedMessage = {
            sender.uid: encryptedSenderReplied['aesEncryptedData'],
            contactUID: encryptedReceiverReplied['aesEncryptedData'],
          };
          tempRepliedAESKey = {
            sender.uid: encryptedSenderReplied['aesKeyEncrypted'],
            contactUID: encryptedReceiverReplied['aesKeyEncrypted'],
          };
        }

        // Create the encrypted message model for direct messages
        messageModel = MessageModel(
          senderUID: sender.uid,
          senderName: sender.name,
          senderImage: sender.image,
          contactUID: contactUID,
          message: '',
          tempMessage: {
            sender.uid: encryptedSenderData['aesEncryptedData'],
            contactUID: encryptedReceiverData['aesEncryptedData'],
          },
          messageType: messageType,
          timeSent: DateTime.now(),
          messageId: messageId,
          isSeen: false,
          repliedMessage: '',
          tempRepliedMessage: tempRepliedMessage,
          repliedTo: repliedTo,
          repliedMessageType: repliedMessageType,
          reactions: [],
          isSeenBy: [sender.uid],
          deletedBy: [],
          aesKeyEncrypted: {
            sender.uid: encryptedSenderData['aesKeyEncrypted'],
            contactUID: encryptedReceiverData['aesKeyEncrypted'],
          },
          aesKeyMessageReplied: tempRepliedAESKey,
        );
      }

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

        // Get group members and send notifications
        final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
        final members = List<String>.from(groupDoc.data()?['membersUIDs'] ?? []);
        print("Member$members");
        
        for (var memberId in members) {
          if (memberId != sender.uid) {
            final memberDoc = await _firestore.collection('users').doc(memberId).get();
            final fcmToken = memberDoc.data()?['token'];
            print("fcmToken${fcmToken}");
            print("Hisxksmxksx");
            if (fcmToken != null) {
              await sendNotification(
                token: fcmToken,
                title: 'New message in ${groupDoc.data()?['groupName']}',
                body: '${sender.name}: $message',
                data: {
                  'notificationType': Constants.groupChatNotification,
                  'groupModel': jsonEncode({
                    'groupId': groupId,
                    'groupName': groupDoc.data()?['groupName'],
                    'senderImage': groupDoc.data()?['groupImage'],
                    'createdAt': groupDoc.data()?['createdAt'],
                    'membersUIDs': groupDoc.data()?['membersUIDs'],
                    'adminsUIDs': groupDoc.data()?['adminsUIDs'],
                    'groupType': groupDoc.data()?['groupType'],
                  }),
                },
              );
            }
          }
        }

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
          // additionalData: {
          //   'encryptedAESKey': encryptedData['encryptedAESKey'],
          //   'iv': encryptedData['iv'],
          // },
        );

        // Get contact's FCM token and send notification
        final contactDoc = await _firestore.collection('users').doc(contactUID).get();
        final fcmToken = contactDoc.data()?['token'];
        
        if (fcmToken != null) {
          await sendNotification(
            token: fcmToken,
            title: 'New Message',
            body: '${sender.name}: $message',
            data: {
              'notificationType': Constants.chatNotification,
              'contactUID': sender.uid,
              'contactName': sender.name,
              'senderImage': sender.image,
            },
          );
        }

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

      MessageModel messageModel;
      if(groupId.isNotEmpty){
        final groupData = await _firestore.collection('groups').doc(groupId).get();
        final groupPublicKeyPEM = groupData.data()?['publicKey'];

        if (groupPublicKeyPEM == null) {
          throw Exception("Group public key not found.");
        }
        final groupPublicKey = decodePublicKeyFromPem(groupPublicKeyPEM);


        Map<String, dynamic> tempRepliedMessage = {};
        Map<String, dynamic> tempRepliedAESKey = {};

        if (repliedMessage.isNotEmpty) {
          final encryptedRepliedString =
          hybridEncrypt(repliedMessage, groupPublicKey);

          final encryptedReplied =
          jsonDecode(encryptedRepliedString);


          tempRepliedMessage = {
            groupId: encryptedReplied['aesEncryptedData'],
          };

          tempRepliedAESKey = {
            groupId: encryptedReplied['aesKeyEncrypted'],
          };
        }
        // 3. update/set the messagemodel
        messageModel = MessageModel(
            senderUID: sender.uid,
            senderName: sender.name,
            senderImage: sender.image,
            contactUID: contactUID,
            message: '',
            tempFileMessage: fileUrl,
            messageType: messageType,
            timeSent: DateTime.now(),
            messageId: messageId,
            isSeen: false,
            repliedMessage: '',
            tempRepliedFileMessage: fileUrl,
            tempRepliedMessage: tempRepliedMessage,
            repliedTo: repliedTo,
            repliedMessageType: repliedMessageType,
            reactions: [],
            isSeenBy: [sender.uid],
            deletedBy: [],
            aesKeyMessageReplied: tempRepliedAESKey);
      }else {
        final recipientData =
        await _firestore.collection('users').doc(contactUID).get();
        final recipientPublicKeyPEM = recipientData.data()?['publicKey'];
        final senderPublicKeyPEM = sender.publicKey;

        if (recipientPublicKeyPEM == null || senderPublicKeyPEM == null) {
          throw Exception("Public keys not found.");
        }

        final recipientPublicKey = decodePublicKeyFromPem(
            recipientPublicKeyPEM);
        final senderPublicKey = decodePublicKeyFromPem(senderPublicKeyPEM);

        Map<String, dynamic> tempRepliedMessage = {};
        Map<String, dynamic> tempRepliedAESKey = {};

        if (repliedMessage.isNotEmpty) {
          final encryptedReciverRepliedString =
          hybridEncrypt(repliedMessage, recipientPublicKey);
          final encryptedSenderRepliedString =
          hybridEncrypt(repliedMessage, senderPublicKey);

          final encryptedReciverReplied =
          jsonDecode(encryptedReciverRepliedString);
          final encryptedSenderReplied = jsonDecode(
              encryptedSenderRepliedString);

          tempRepliedMessage = {
            sender.uid: encryptedSenderReplied['aesEncryptedData'],
            contactUID: encryptedReciverReplied['aesEncryptedData'],
          };

          tempRepliedAESKey = {
            sender.uid: encryptedSenderReplied['aesKeyEncrypted'],
            contactUID: encryptedReciverReplied['aesKeyEncrypted'],
          };
        }

        // 3. update/set the messagemodel
        messageModel = MessageModel(
            senderUID: sender.uid,
            senderName: sender.name,
            senderImage: sender.image,
            contactUID: contactUID,
            message: '',
            tempFileMessage: fileUrl,
            messageType: messageType,
            timeSent: DateTime.now(),
            messageId: messageId,
            isSeen: false,
            repliedMessage: '',
            tempRepliedFileMessage: fileUrl,
            tempRepliedMessage: tempRepliedMessage,
            repliedTo: repliedTo,
            repliedMessageType: repliedMessageType,
            reactions: [],
            isSeenBy: [sender.uid],
            deletedBy: [],
            aesKeyMessageReplied: tempRepliedAESKey);
      }
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

        // set loading to false
        setLoading(false);
        onSucess();
        // send notification to group members
        final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
        final List<String> members = List<String>.from(groupDoc.data()?['members'] ?? []);
        for (var memberId in members) {
          if (memberId != sender.uid) {
            final memberDoc = await _firestore.collection('users').doc(memberId).get();
            final token = memberDoc.data()?['token'];
            if (token != null) {
              await NotificationServices.sendNotification(
                token: token,
                title: '${sender.name} sent a file in ${groupDoc.data()?['groupName']}',
                body: 'File: ${messageType.name}',
                data: {
                  'notificationType': Constants.groupChatNotification,
                  'groupModel': jsonEncode({
                    'groupId': groupId,
                    'groupName': groupDoc.data()?['groupName'],
                    'senderImage': groupDoc.data()?['groupImage'],
                    'createdAt': groupDoc.data()?['createdAt'],
                    'membersUIDs': groupDoc.data()?['membersUIDs'],
                    'adminsUIDs': groupDoc.data()?['adminsUIDs'],
                    'groupType': groupDoc.data()?['groupType'],
                  }),
                },
              );
            }
          }
        }
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

        // send notification to contact
        final contactDoc = await _firestore.collection('users').doc(contactUID).get();
        final token = contactDoc.data()?['token'];
        if (token != null) {
          await NotificationServices.sendNotification(
            token: token,
            title: sender.name,
            body: 'File: ${messageType.name}',
            data: {
              'notificationType': Constants.chatNotification,
              'contactUID': sender.uid,
              'contactName': sender.name,
              'senderImage': sender.image,
              'messageType': messageType.name,
            },
          );
        }

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
    //  Map<String, dynamic>? additionalData,
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
        tempMessage: messageModel.tempMessage,
        tempFileMessage: messageModel.tempFileMessage,
        // messageForSender: messageModel.messageForSender,
        // messageForReceiver: messageModel.messageForReceiver,
        messageType: messageModel.messageType,
        timeSent: messageModel.timeSent,
        isSeen: false,
        aesKeyEncrypted: messageModel.aesKeyEncrypted,
        // aesKeyEncryptedForSender: messageModel.aesKeyEncryptedForSender,
        // aesKeyEncryptedForReceiver: messageModel.aesKeyEncryptedForReceiver,

        // additionalData:additionalData
      );

      // 2. initialize last message for the contact
      final contactLastMessage = senderLastMessage.copyWith(
        contactUID: messageModel.senderUID,
        contactName: messageModel.senderName,
        contactImage: messageModel.senderImage,
        aesKeyEncrypted: messageModel.aesKeyEncrypted,
        // aesKeyEncryptedForSender: messageModel.aesKeyEncryptedForSender,
        // aesKeyEncryptedForReceiver: messageModel.aesKeyEncryptedForReceiver,
        // additionalData:additionalData
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

    // Get the sender's information for notification
    final senderDoc = await _firestore.collection('users').doc(senderUID).get();
    final senderName = senderDoc.data()?['name'] ?? 'Someone';


    try {
      // 1. check if its a group message
      if (groupId) {
        print("inside the group reaction");
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

          // Send notification to message sender if they're not the one reacting
          if (message.senderUID != senderUID) {
            final groupDoc = await _firestore.collection(Constants.groups).doc(contactUID).get();
            final groupName = groupDoc.data()?['groupName'] ?? 'Group';
            final senderFCMToken = (await _firestore.collection('users').doc(message.senderUID).get()).data()?['token'];
          
            if (senderFCMToken != null) {
              await sendNotification(
                token: senderFCMToken,
                title: groupName,
                body: '$senderName reacted with $reaction to your message',
                data: {
                  'notificationType': Constants.groupChatNotification,
                  'groupId': contactUID,
                  'messageId': messageId
                },
              );
            }
          }
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

          // Send notification to message sender if they're not the one reacting
          if (message.senderUID != senderUID) {
            final contactFCMToken = (await _firestore.collection('users').doc(message.senderUID).get()).data()?['token'];
          
            if (contactFCMToken != null) {
              await sendNotification(
                token: contactFCMToken,
                title: senderName,
                body: 'reacted with $reaction to your message',
                data: {
                  'notificationType': Constants.chatNotification,
                  'contactUID': senderUID,
                  'contactName': senderName,
                  'messageId': messageId
                },
              );
            }
          }
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
        // final privateKey = EncryptionUtils.decodePrivateKeyFromPem(privateKeyPem);
        final privateKey = decodePrivateKeyFromPem(privateKeyPem);
        print("Private key successfully decoded: $privateKey");

        return snapshot.docs.map((doc) {
          try {
            var messageData = doc.data();
            var lastMessage = LastMessageModel.fromMap(messageData);
            final aesKeyEncrypted = lastMessage.aesKeyEncrypted?[userId];
            final aesEncryptedData = lastMessage.tempMessage?[userId];

            // Check if message contains additionalData for decryption
            if (aesKeyEncrypted != null &&
                aesEncryptedData != null &&
                lastMessage.messageType == MessageEnum.text) {
              final encryptedData = {
                'aesKeyEncrypted': aesKeyEncrypted,
                'aesEncryptedData': aesEncryptedData,
              };

              final decryptedMessage =
                  hybridDecrypt(jsonEncode(encryptedData), privateKey);
              print("decryptedMessage $decryptedMessage");
              // Update the last message with the decrypted message
              lastMessage = lastMessage.copyWith(
                  contactUID: lastMessage.contactUID,
                  contactName: lastMessage.contactName,
                  contactImage: lastMessage.contactImage,
                  message: decryptedMessage); // Update the message
            } else {
              lastMessage = lastMessage.copyWith(
                  contactUID: lastMessage.contactUID,
                  contactName: lastMessage.contactName,
                  contactImage: lastMessage.contactImage,
                  message: lastMessage.tempFileMessage); // Update the message
            }
            // else if(lastMessage.contactUID == userId &&
            //     lastMessage.aesKeyEncryptedForReceiver != null&&lastMessage.messageForReceiver==MessageEnum.text){
            //   final aesKeyEncrypted = messageData['aesKeyEncryptedForReceiver'];
            //   final encryptedData = {
            //     'aesKeyEncrypted': aesKeyEncrypted,
            //     'aesEncryptedData': messageData['messageForReceiver'],
            //   };

            //   final decryptedMessage =
            //       hybridDecrypt(jsonEncode(encryptedData), privateKey);
            //   print("decryptedMessage $decryptedMessage");
            //   // Update the last message with the decrypted message
            //   lastMessage = lastMessage.copyWith(
            //       contactUID: lastMessage.contactUID,
            //       contactName: lastMessage.contactName,
            //       contactImage: lastMessage.contactImage,
            //       message: decryptedMessage); // Update the message
            // }

            return lastMessage;
          } catch (e) {
            print("Error decrypting message for document ${doc.id}: $e");
            return LastMessageModel.fromMap(
                doc.data()); // Return the unmodified message in case of error
          }
        }).toList();
      } catch (e, stacktrace) {
        print("Error decoding private key or during decryption: $e");
        print(stacktrace);
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
          .asyncMap((snapshot) async{
        final groupData = await _firestore.collection('groups').doc(isGroup).get();
        final groupPrivateKeyPEM = groupData.data()?['privateKey'];

        if (groupPrivateKeyPEM == null) {
          throw Exception("Group private key not found.");
        }
        
        final groupPrivateKey = decodePrivateKeyFromPem(groupPrivateKeyPEM);

        return snapshot.docs.map((doc) {
          var messageData = doc.data();
          var message =  MessageModel.fromMap(messageData);
          final aesKeyEncrypted = message.aesKeyEncrypted?[isGroup];
          final aesEncryptedData = message.tempMessage?[isGroup];
          final aesKeyReplied = message.aesKeyMessageReplied?[isGroup];

          final aesEncryptedRepliedData = message.tempRepliedMessage?[isGroup];
          var decryptedRepliedMessage = '';
          if (aesEncryptedRepliedData != null) {
            // print("Helloooooo");
            final encryptedRepliedData = {
              'aesKeyEncrypted': aesKeyReplied,
              'aesEncryptedData': aesEncryptedRepliedData,
            };
            print("encryptedRepliedData $encryptedRepliedData");
            decryptedRepliedMessage =
                hybridDecrypt(jsonEncode(encryptedRepliedData), groupPrivateKey);
            print("decryptedRepliedMessage $decryptedRepliedMessage");
          }

          if (message.messageType != MessageEnum.text) {
            message = message.copyWith(
                userId: userId,
                decryptedMessage: message.tempFileMessage,
                decryptedRepliedMessage: decryptedRepliedMessage);
          }else{
            final encryptedData = {
              'aesKeyEncrypted': aesKeyEncrypted,
              'aesEncryptedData': aesEncryptedData,
            };

            final decryptedMessage =
            hybridDecrypt(jsonEncode(encryptedData), groupPrivateKey);

            // Update the last message with the decrypted message
            message = message.copyWith(
                userId: userId,
                decryptedMessage: decryptedMessage,
                decryptedRepliedMessage: decryptedRepliedMessage);
          }

            return message;
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
          .asyncMap((snapshot) async {
        final privateKeyPem = await _getUserPrivateKey(userId);

        if (privateKeyPem == null) {
          throw Exception("User private key not found.");
        }
        final privateKey = decodePrivateKeyFromPem(privateKeyPem);

        return snapshot.docs.map((doc) {
          var messageData = doc.data();
          var message = MessageModel.fromMap(messageData);
          final aesKeyEncrypted = message.aesKeyEncrypted?[userId];
          final aesEncryptedData = message.tempMessage?[userId];
          final aesKeyReplied = message.aesKeyMessageReplied?[userId];

          final aesEncryptedRepliedData = message.tempRepliedMessage?[userId];

          // print("messaffeeelkke ${aesEncryptedRepliedData}");

          print("Private key successfully decoded: $privateKey");
          print("aesKeyEncrypted $userId $aesKeyEncrypted");
          print("aesEncryptedData $userId $aesEncryptedData");
          var decryptedRepliedMessage = '';
          if (aesEncryptedRepliedData != null) {
            // print("Helloooooo");
            final encryptedRepliedData = {
              'aesKeyEncrypted': aesKeyReplied,
              'aesEncryptedData': aesEncryptedRepliedData,
            };
            print("encryptedRepliedData $encryptedRepliedData");
            decryptedRepliedMessage =
                hybridDecrypt(jsonEncode(encryptedRepliedData), privateKey);
            print("decryptedRepliedMessage $decryptedRepliedMessage");
          }

          if (message.messageType != MessageEnum.text){
            print("hello");
            // var decryptedRepliedMessage = '';
            // if(aesEncryptedRepliedData !=null){
            // print("Helloooooo");
            //   final encryptedRepliedData={
            //   'aesKeyEncrypted': aesKeyReplied,
            //   'aesEncryptedData': aesEncryptedRepliedData,
            //   };
            //   print("encryptedRepliedData $encryptedRepliedData");
            //   decryptedRepliedMessage =
            //     hybridDecrypt(jsonEncode(encryptedRepliedData), privateKey);
            // print("decryptedRepliedMessage $decryptedRepliedMessage");

            // }
            message = message.copyWith(
                userId: userId,
                decryptedMessage: message.tempFileMessage,
                decryptedRepliedMessage: decryptedRepliedMessage);
          }else{
            final encryptedData = {
              'aesKeyEncrypted': aesKeyEncrypted,
              'aesEncryptedData': aesEncryptedData,
            };

            final decryptedMessage =
                hybridDecrypt(jsonEncode(encryptedData), privateKey);

            // Update the last message with the decrypted message
            message = message.copyWith(
                userId: userId,
                decryptedMessage: decryptedMessage,
                decryptedRepliedMessage: decryptedRepliedMessage);
            // .copyWith(
            //     contactUID: message.contactUID,
            //     contactName: message.contactName,
            //     contactImage: message.contactImage,
            //     message:decryptedMessage); // Update the message
          }
          // else if(message.contactUID == userId &&
          //     message.aesKeyEncryptedForReceiver != null&&message.messageForReceiver==MessageEnum.text){
          //   final aesKeyEncrypted = messageData['aesKeyEncryptedForReceiver'];
          //   final encryptedData = {
          //     'aesKeyEncrypted': aesKeyEncrypted,
          //     'aesEncryptedData': messageData['messageForReceiver'],
          //   };

          //   final decryptedMessage =
          //       hybridDecrypt(jsonEncode(encryptedData), privateKey);
          //   print("decryptedMessage $decryptedMessage");
          //   // Update the last message with the decrypted message
          //     message =
          //       message.copyWith(userId: userId, decryptedMessage: decryptedMessage);
          // }
          print("message $message");
          return message;
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
    try {
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
      return _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .where(Constants.isSeen, isEqualTo: false)
          .where(Constants.senderUID, isNotEqualTo: userId)
          .snapshots()
          .map((event) {
        try {
          int unreadCount = event.docs.length;
          print("Unread messages for $contactUID: $unreadCount");
          return unreadCount;
        } catch (e) {
          print("Error processing unread count: $e");
          return 0; // Return 0 unread messages in case of error
        }
      }).handleError((error) {
        print("Firestore stream error (private messages): $error");
      });
    }
    } catch (e) {
      print("Unexpected error in getUnreadMessagesStream: $e");
      return Stream.value(0); // Return a fallback stream emitting 0
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

      // 3. update both current user and contact messages as deleted for everyone
      await Future.wait([
        _firestore
            .collection(Constants.users)
            .doc(currentUserId)
            .collection(Constants.chats)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
          Constants.deletedBy: FieldValue.arrayUnion([currentUserId, contactUID])
        }),
        _firestore
            .collection(Constants.users)
            .doc(contactUID)
            .collection(Constants.chats)
            .doc(currentUserId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({
          Constants.deletedBy: FieldValue.arrayUnion([currentUserId, contactUID])
        })
      ]);

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

  //   Future<void> updateTypingStatus({
  //   required String chatId,
  //   required String currentUserId,
  //   required bool isTyping,
  // }) async {
  //   try {
  //     // Cancel any existing timer
  //     _typingTimer?.cancel();

  //     await _firestore
  //         .collection(Constants.users)
  //         .doc(chatId)
  //         .collection(Constants.chats)
  //         .doc(currentUserId)
  //         .update({
  //       'isTyping': isTyping,
  //       'typingUserId': isTyping ? currentUserId : '',
  //     });

  //     if (isTyping) {
  //       // Start timer to automatically set typing to false after duration
  //       _typingTimer = Timer(_typingDuration, () async {
  //         await _firestore
  //             .collection(Constants.users)
  //             .doc(chatId)
  //             .collection(Constants.chats)
  //             .doc(currentUserId)
  //             .update({
  //           'isTyping': false,
  //           'typingUserId': '',
  //         });
  //       });
  //     }
  //   } catch (e) {
  //     print('Error updating typing status: $e');
  //   }
  // }

  Future<void> updateTypingStatus({
    required String userId,
    required String chatRoomId,
    required bool isTyping,
  }) async {
    try {
      print('Updating typing status - User: $userId, ChatRoom: $chatRoomId, isTyping: $isTyping');
      
      // Cancel any existing timer
      if (_typingTimer != null) {
        print('Cancelling existing typing timer');
        _typingTimer?.cancel();
      }

      // Update typing status and typingInChatRoom in user document
      print('Updating Firestore document for user: $userId');
      await _firestore
          .collection(Constants.users)
          .doc(userId)
          .update({
        'isTyping': isTyping,
        'typingInChatRoom': isTyping ? chatRoomId : null,
      }).then((_) => print('Firestore update successful'))
        .catchError((error) => print('Firestore update failed: $error'));

      if (isTyping) {
        print('Starting typing timer for auto-reset');
        // Start timer to automatically set typing to false after duration
        _typingTimer = Timer(_typingDuration, () async {
          print('Typing timer expired - resetting status');
          try {
            await _firestore
                .collection(Constants.users)
                .doc(userId)
                .update({
                  'isTyping': false,
                  'typingInChatRoom': null,
                });
            print('Successfully reset typing status after timer');
          } catch (timerError) {
            print('Error resetting typing status after timer: $timerError');
          }
        });
      }
    } catch (e) {
      print('Error in updateTypingStatus: $e');
    }
  }
  
    void listenForTypingStatus(String chatId, String currentUserId) {
      _firestore.collection(Constants.users)
            .doc(currentUserId)
            .snapshots().listen((snapshot) {
        if (snapshot.exists) {
          print("isTyping ${snapshot['isTyping']}");
          _isTyping = snapshot['isTyping'] ?? false;
          _typingUserId = snapshot['typingInChatRoom'] ?? '';
          notifyListeners();
        }
      });
  }

//   Future<void> updateGroupTypingStatus({
//   required String groupId,
//   required String userId,
//   required bool isTyping,
// }) async {
//   try {
//     if (isTyping) {
//       await _firestore.collection('groups').doc(groupId).update({
//         'typingUsers': FieldValue.arrayUnion([userId]),
//       });
//     } else {
//       await _firestore.collection('groups').doc(groupId).update({
//         'typingUsers': FieldValue.arrayRemove([userId]),
//       });
//     }
//   } catch (e) {
//     print('Error updating group typing status: $e');
//   }
// }

// Listen for group typing status
void listenForGroupTypingStatus(String groupId) {
  _firestore.collection('groups').doc(groupId).snapshots().listen((snapshot) {
    if (snapshot.exists) {
      final typingUsers = List<String>.from(snapshot['typingUsers'] ?? []);
      _typingUserId = typingUsers.isNotEmpty ? typingUsers.first : '';
      _isTyping = typingUsers.isNotEmpty;
      notifyListeners();
    }
  });
}
}
