
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/enums/enums.dart';

class LastMessageModel {
  String senderUID;
  String contactUID;
  String contactName;
  String contactImage;
  String message;
    Map<String, dynamic>? tempMessage; 
  String? tempFileMessage;
  String? messageForSender;
  String? messageForReceiver;
  MessageEnum messageType;
  DateTime timeSent;
  bool isSeen;
  Map<String, dynamic>? aesKeyEncrypted;
  String? typingUserId;
  String? isTyping;
  // final String? aesKeyEncryptedForSender;
  // final String? aesKeyEncryptedForReceiver;
  // Map<String, dynamic>? additionalData; // New field for extra metadata


  LastMessageModel({
    required this.senderUID,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.message,
        this.tempMessage,
        this.tempFileMessage,
    this.messageForSender,
    this.messageForReceiver,
    required this.messageType,
    required this.timeSent,
    required this.isSeen,
    // this.additionalData,
    this.aesKeyEncrypted,
    this.typingUserId,
    this.isTyping
    // this.aesKeyEncryptedForSender,
    // this.aesKeyEncryptedForReceiver,

  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.senderUID: senderUID,
      Constants.contactUID: contactUID,
      Constants.contactName: contactName,
      Constants.contactImage: contactImage,
      Constants.message: message,
      Constants.tempFileMessage: tempFileMessage,
      Constants.tempMessage: tempMessage,
      Constants.messageForSender: messageForSender,
      Constants.messageForReceiver: messageForReceiver,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent.microsecondsSinceEpoch,
      Constants.isSeen: isSeen,
      Constants.aesKeyEncrypted: aesKeyEncrypted,
      Constants.typingUserId: typingUserId,
      Constants.isTyping: isTyping,

      // Constants.aesKeyEncryptedForSender: aesKeyEncryptedForSender,
      // Constants.aesKeyEncryptedForReceiver: aesKeyEncryptedForReceiver
      // Constants.additionalData: additionalData, // Include additionalData

    };
  }

  // from map
  factory LastMessageModel.fromMap(Map<String, dynamic> map) {
    // Decrypt the message after mapping
    return LastMessageModel(
      senderUID: map[Constants.senderUID] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      contactName: map[Constants.contactName] ?? '',
      contactImage: map[Constants.contactImage] ?? '',
      message: map[Constants.message] ?? '',
      tempMessage: map[Constants.tempMessage] ?? {},
      tempFileMessage: map[Constants.tempFileMessage] ?? '',
      messageForSender: map[Constants.messageForSender] ?? '',
      messageForReceiver: map[Constants.messageForReceiver] ?? '',
      messageType: map[Constants.messageType].toString().toMessageEnum(),
      timeSent: DateTime.fromMicrosecondsSinceEpoch(map[Constants.timeSent]),
      isSeen: map[Constants.isSeen] ?? false,
      aesKeyEncrypted: map[Constants.aesKeyEncrypted] ?? null,
      typingUserId: map[Constants.typingUserId] ?? null,
      isTyping: map[Constants.isTyping]?.toString() ?? null,
      // aesKeyEncryptedForSender: map[Constants.aesKeyEncryptedForSender] ?? null,
      // aesKeyEncryptedForReceiver: map[Constants.aesKeyEncryptedForReceiver] ?? null,
      // additionalData: map[Constants.additionalData] ?? {}, // Extract additionalData
    );
  }

  // Optional: You can use this method to generate a copy of the object with some updated fields
  copyWith({
    required String contactUID,
    required String contactName,
    required String contactImage,
    String? message,
    Map<String, dynamic>? aesKeyEncrypted,
    // String? aesKeyEncryptedForSender,
    // String? aesKeyEncryptedForReceiver

    // Map<String, dynamic>? additionalData
  }) {
    return LastMessageModel(
      senderUID: senderUID,
      contactUID: contactUID,
      contactName: contactName,
      contactImage: contactImage,
      message: message ?? this.message,
      tempMessage: tempMessage,
      tempFileMessage: tempFileMessage,
      // messageForSender: messageForSender,
      // messageForReceiver: messageForReceiver,
      messageType: messageType,
      timeSent: timeSent,
      isSeen: isSeen,
      aesKeyEncrypted:  aesKeyEncrypted,
      typingUserId: typingUserId,
      isTyping: isTyping,
      // aesKeyEncryptedForSender: aesKeyEncryptedForSender,
      // aesKeyEncryptedForReceiver: aesKeyEncryptedForReceiver
      // additionalData: additionalData ?? this.additionalData, // Update additionalData
    );
  }
}

