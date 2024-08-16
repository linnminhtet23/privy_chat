import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:privy_chat/models/user_model.dart';
import 'package:privy_chat/utils/notification_utils.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationUtils _notificationUtils = NotificationUtils();

  // Fetches pending friend requests for a specific user
  Future<List<Map<String, dynamic>>> getFriendRequests(String userId) async {
    final querySnapshot = await _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, 'data': doc.data()})
        .toList();
  }

  // Retrieves a user's information by their ID
  Future<UserModel> getUserById(String userId) async {
    final docSnapshot = await _firestore.collection('users').doc(userId).get();
    if (!docSnapshot.exists) {
      throw Exception('User not found');
    }
    return UserModel.fromMap(docSnapshot.data()!, docSnapshot.id);
  }

  // Responds to a friend request and updates the status
  Future<void> respondToFriendRequest(
      String requestId, String response) async {
    final requestDoc = await _firestore.collection('friendRequests').doc(requestId).get();
    final requestData = requestDoc.data();
    if (requestData == null) {
      throw Exception('Friend request not found');
    }

    final senderId = requestData['senderId'];
    final receiverId = requestData['receiverId'];

    if (response == 'accept') {
      await _addFriend(senderId, receiverId);
      await _addFriend(receiverId, senderId);
      await _sendNotification(
        senderId,
        'Friend Request Accepted',
        'Your friend request has been accepted.',
      );
    }

    await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': response});
  }

  // Adds a friend by updating both users' friend lists
  Future<void> _addFriend(String userId, String friendId) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final friendDocRef = _firestore.collection('users').doc(friendId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(userDocRef, {
        'friends': FieldValue.arrayUnion([friendId])
      });
      transaction.update(friendDocRef, {
        'friends': FieldValue.arrayUnion([userId])
      });
    });
  }

  // Removes a friend by updating both users' friend lists
  Future<void> removeFriend(String userId, String friendId) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final friendDocRef = _firestore.collection('users').doc(friendId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(userDocRef, {
        'friends': FieldValue.arrayRemove([friendId])
      });
      transaction.update(friendDocRef, {
        'friends': FieldValue.arrayRemove([userId])
      });
    });
  }

  // Blocks a user by updating the blocked list
  Future<void> blockUser(String userId, String blockedId) async {
    await _firestore.collection('users').doc(userId).update({
      'blocked': FieldValue.arrayUnion([blockedId])
    });
  }

  // Mutes a user by updating the muted list
  Future<void> muteUser(String userId, String mutedId) async {
    await _firestore.collection('users').doc(userId).update({
      'muted': FieldValue.arrayUnion([mutedId])
    });
  }

  // Sends a friend request to another user
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    await _firestore.collection('friendRequests').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final receiverUser = await getUserById(receiverId);
    final receiverToken = receiverUser.token; 

    if (receiverToken != null) {
      await _notificationUtils.sendNotification(
        token: receiverToken,
        title: 'New Friend Request',
        body: 'You have a new friend request from $senderId.',
      );
    }
  }

  // Sends a notification to a user
  Future<void> _sendNotification(String userId, String title, String body) async {
    final user = await getUserById(userId);
    final token = user.token;

    if (token != null) {
      await _notificationUtils.sendNotification(
        token: token,
        title: title,
        body: body,
      );
    }
  }

  // Searches for users by username
  Future<List<UserModel>> searchUsers(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
