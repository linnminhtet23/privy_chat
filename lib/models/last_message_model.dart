import 'dart:convert';
import 'dart:typed_data';

import 'package:privy_chat/constants.dart';
import 'package:privy_chat/enums/enums.dart';
import 'package:privy_chat/utils/encryption_utils.dart';

class LastMessageModel {
  String senderUID;
  String contactUID;
  String contactName;
  String contactImage;
  String message;
  MessageEnum messageType;
  DateTime timeSent;
  bool isSeen;
  Map<String, dynamic>? additionalData; // New field for extra metadata


  LastMessageModel({
    required this.senderUID,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.isSeen,
    this.additionalData,

  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.senderUID: senderUID,
      Constants.contactUID: contactUID,
      Constants.contactName: contactName,
      Constants.contactImage: contactImage,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent.microsecondsSinceEpoch,
      Constants.isSeen: isSeen,
      Constants.additionalData: additionalData, // Include additionalData

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
      message: map[Constants.message] ?? '', // Decrypted message
      messageType: map[Constants.messageType].toString().toMessageEnum(),
      timeSent: DateTime.fromMicrosecondsSinceEpoch(map[Constants.timeSent]),
      isSeen: map[Constants.isSeen] ?? false,
      additionalData: map[Constants.additionalData] ?? {}, // Extract additionalData
    );
  }

  // Optional: You can use this method to generate a copy of the object with some updated fields
  copyWith({
    required String contactUID,
    required String contactName,
    required String contactImage,
    String? message,
    Map<String, dynamic>? additionalData
  }) {
    return LastMessageModel(
      senderUID: senderUID,
      contactUID: contactUID,
      contactName: contactName,
      contactImage: contactImage,
      message: message ?? this.message,
      messageType: messageType,
      timeSent: timeSent,
      isSeen: isSeen,
      additionalData: additionalData ?? this.additionalData, // Update additionalData
    );
  }
}

