import '../constants.dart';
import '../enums/enums.dart';

class MessageModel {
  final String senderUID;
  final String senderName;
  final String senderImage;
  final String contactUID;
  final String message;
  Map<String, dynamic>? tempMessage; 
  String? tempFileMessage;
  // String? messageForSender;
  // String? messageForReceiver;
  final MessageEnum messageType;
  final DateTime timeSent;
  final String messageId;
  final bool isSeen;
  final String repliedMessage;
  final Map<String, dynamic>? tempRepliedMessage;
  final String? tempRepliedFileMessage;

  final String repliedTo;
  final MessageEnum repliedMessageType;
  final List<String> reactions;
  final List<String> isSeenBy;
  final List<String> deletedBy;
  final Map<String, dynamic>? aesKeyEncrypted;
  final Map<String, dynamic>? aesKeyMessageReplied;
  // final String? aesKeyEncryptedForSender;
  // final String? aesKeyEncryptedForReceiver;

  // final Map<String, dynamic>? additionalData; // New field for extra metadata

  MessageModel({
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.contactUID,
    required this.message,
    this.tempMessage,
    this.tempFileMessage,
    // this.messageForSender,
    // this.messageForReceiver,
    required this.messageType,
    required this.timeSent,
    required this.messageId,
    required this.isSeen,
    required this.repliedMessage,
    this.tempRepliedMessage,
    this.tempRepliedFileMessage,
    required this.repliedTo,
    required this.repliedMessageType,
    required this.reactions,
    required this.isSeenBy,
    required this.deletedBy,
    this.aesKeyEncrypted,
    this.aesKeyMessageReplied
    // this.aesKeyEncryptedForSender,
    // this.aesKeyEncryptedForReceiver,
    // this.additionalData,
  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.senderUID: senderUID,
      Constants.senderName: senderName,
      Constants.senderImage: senderImage,
      Constants.contactUID: contactUID,
      Constants.message: message,
      Constants.tempMessage: tempMessage,
      Constants.tempFileMessage: tempFileMessage,
      // Constants.messageForSender: messageForSender,
      // Constants.messageForReceiver: messageForReceiver,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent.millisecondsSinceEpoch,
      Constants.messageId: messageId,
      Constants.isSeen: isSeen,
      Constants.repliedMessage: repliedMessage,
      Constants.tempRepliedMessage: tempRepliedMessage,
      Constants.tempRepliedFileMessage: tempRepliedFileMessage,
      Constants.repliedTo: repliedTo,
      Constants.repliedMessageType: repliedMessageType.name,
      Constants.reactions: reactions,
      Constants.isSeenBy: isSeenBy,
      Constants.deletedBy: deletedBy,
      Constants.aesKeyEncrypted: aesKeyEncrypted,
      Constants.aesKeyMessageReplied: aesKeyMessageReplied
      // Constants.aesKeyEncryptedForSender: aesKeyEncryptedForSender,
      //       Constants.aesKeyEncryptedForReceiver: aesKeyEncryptedForReceiver

      // Constants.additionalData: additionalData, // Include additionalData
    };
  }

  // from map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderUID: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      message: map[Constants.message] ?? '',
      tempMessage: map[Constants.tempMessage] ?? {},
      tempFileMessage: map[Constants.tempFileMessage] ?? '',
      // messageForSender: map[Constants.messageForSender] ?? '',
      // messageForReceiver: map[Constants.messageForReceiver] ?? '',
      messageType: map[Constants.messageType].toString().toMessageEnum(),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map[Constants.timeSent]),
      messageId: map[Constants.messageId] ?? '',
      isSeen: map[Constants.isSeen] ?? false,
      repliedMessage: map[Constants.repliedMessage] ?? '',
      tempRepliedMessage: map[Constants.tempRepliedMessage] ?? {},
      tempRepliedFileMessage: map[Constants.tempRepliedFileMessage] ?? '',
      repliedTo: map[Constants.repliedTo] ?? '',
      repliedMessageType:
      map[Constants.repliedMessageType].toString().toMessageEnum(),
      reactions: List<String>.from(map[Constants.reactions] ?? []),
      isSeenBy: List<String>.from(map[Constants.isSeenBy] ?? []),
      deletedBy: List<String>.from(map[Constants.deletedBy] ?? []),
      aesKeyEncrypted: map[Constants.aesKeyEncrypted] ?? {},
      aesKeyMessageReplied: map[Constants.aesKeyMessageReplied] ?? {},

      // aesKeyEncryptedForSender: map[Constants.aesKeyEncryptedForSender] ?? null,
      // aesKeyEncryptedForReceiver: map[Constants.aesKeyEncryptedForReceiver] ?? null,

      // additionalData: map[Constants.additionalData] ?? {}, // Extract additionalData
    );
  }

  copyWith({String? userId, String? decryptedMessage, String?decryptedRepliedMessage}) {
    print("decryptedRepliedMessage $decryptedRepliedMessage");
    return MessageModel(
      senderUID: senderUID,
      senderName: senderName,
      senderImage: senderImage,
      contactUID: userId ?? contactUID,
      message:  decryptedMessage?? this.message,
      tempMessage: tempMessage,
      tempFileMessage: tempFileMessage,
      // messageForSender: messageForSender,
      // messageForReceiver: messageForReceiver,
      messageType: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: isSeen,
      repliedMessage: decryptedRepliedMessage?? this.repliedMessage,
      repliedTo: repliedTo,
      repliedMessageType: repliedMessageType,
      tempRepliedMessage: tempRepliedMessage,
      tempRepliedFileMessage: tempRepliedFileMessage,
      reactions: reactions,
      isSeenBy: isSeenBy,
      deletedBy: deletedBy,
      aesKeyEncrypted:aesKeyEncrypted,
      aesKeyMessageReplied: aesKeyMessageReplied
      // aesKeyEncryptedForSender: aesKeyEncryptedForSender,
      // aesKeyEncryptedForReceiver: aesKeyEncryptedForReceiver
      // additionalData: additionalData ?? this.additionalData, // Update additionalData
    );
  }
}
