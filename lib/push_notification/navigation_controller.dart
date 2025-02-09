import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/constants.dart';
import 'package:privy_chat/main_screen/friend_requests_screen.dart';
import 'package:privy_chat/models/group_model.dart';
import 'package:privy_chat/providers/group_provider.dart';
import 'package:provider/provider.dart';

navigationControler({
  required BuildContext context,
  required RemoteMessage message,
}) {
  //if (context == null) return;
  print("notificationType${message.data[Constants.notificationType]}");

  switch (message.data[Constants.notificationType]) {
    case Constants.chatNotification:
      // navigate to chat screen here
      Navigator.pushNamed(
        context,
        Constants.chatScreen,
        arguments: {
          Constants.contactUID: message.data[Constants.contactUID],
          Constants.contactName: message.data[Constants.contactName],
          Constants.contactImage: message.data[Constants.contactImage],
          Constants.groupId: '',
        },
      );
      break;
    case Constants.friendRequestNotification:
      // navigate to friend requests screen
      Navigator.pushNamed(
        context,
        Constants.friendRequestsScreen,
      );
      break;
    case Constants.requestReplyNotification:
      // navigate to friend requests screen
      // navigate to friends screen
      Navigator.pushNamed(
        context,
        Constants.friendsScreen,
      );
      break;
    case Constants.groupRequestNotification:
      // navigate to friend requests screen
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return FriendRequestScreen(
          groupId: message.data[Constants.groupId],
        );
      }));
      break;

    case Constants.groupChatNotification:
      print("group chat noti");
      // parse the JSON string to a map
      Map<String, dynamic> jsonMap =
          jsonDecode(message.data[Constants.groupModel]);
      print("group $jsonMap");

      // transform the map to a simple GroupModel object
      final Map<String, dynamic> flatGroupModelMap =
          flattenGroupModelMap(jsonMap);
      print("flatGroupModelMap $flatGroupModelMap");

      final groupModel = GroupModel.fromMap(flatGroupModelMap);
      log('JSON: $jsonMap');
      log('Flat Map: $flatGroupModelMap');
      log('Group Model: $groupModel');
      // navigate to group screen
      context
          .read<GroupProvider>()
          .setGroupModel(groupModel: groupModel)
          .whenComplete(() {
        Navigator.pushNamed(
          context,
          Constants.chatScreen,
          arguments: {
            Constants.contactUID: groupModel.groupId,
            Constants.contactName: groupModel.groupName,
            Constants.contactImage: groupModel.groupImage,
            Constants.groupId: groupModel.groupId,
          },
        );
      });
      break;
    // case Constants.friendRequestNotification:
    //   // navigate to friend requests screen
    //         Navigator.pushNamed(
    //           context,
    //           Constants.friendRequestsScreen,
    //         );
    // break;
    default:
      print('No Notification');
  }
}

// Function to transform the complex structure into a simple map
Map<String, dynamic> flattenGroupModelMap(Map<String, dynamic> complexMap) {
  Map<String, dynamic> flatMap = {};

  // Check if this is a Firestore document structure
  if (complexMap.containsKey('_fieldsProto')) {
    complexMap['_fieldsProto'].forEach((key, value) {
      switch (value['valueType']) {
        case 'stringValue':
          flatMap[key] = value['stringValue'];
          break;
        case 'booleanValue':
          flatMap[key] = value['booleanValue'];
          break;
        case 'integerValue':
          flatMap[key] = int.parse(value['integerValue']);
          break;
        case 'arrayValue':
          flatMap[key] = value['arrayValue']['values']
              .map<String>((item) => item['stringValue'] as String)
              .toList();
          break;
        default:
          flatMap[key] = null;
      }
    });
  } else {
    // Handle regular JSON object from notification
    flatMap = Map<String, dynamic>.from(complexMap);
  }

  return flatMap;
}
