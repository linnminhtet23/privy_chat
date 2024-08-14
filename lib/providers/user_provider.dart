import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:secure_flutter_chat/models/user_model.dart';
import 'package:secure_flutter_chat/utils/notification_utils.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationUtils _notificationUtils = NotificationUtils();

  Future<List<Map<String, dynamic>>> getFriendRequests(String userId) async {
    final result = await _firestore.collection('friendRequests')
      .where('receiverId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .get();
    return result.docs.map((doc) => {'id': doc.id, 'data': doc.data()}).toList();
  }

  Future<UserModel> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> respondToFriendRequest(String requestId, String response) async {
    final requestDoc = await _firestore.collection('friendRequests').doc(requestId).get();
    final senderId = requestDoc.data()!['senderId'];
    final receiverId = requestDoc.data()!['receiverId'];

    if (response == 'accept') {
      await addFriend(senderId, receiverId);
      await addFriend(receiverId, senderId);
      await _sendNotification(senderId, 'Friend Request Accepted', 'Your friend request has been accepted.');
    } 
       await _firestore.collection('friendRequests').doc(requestId).update({'status': response});
  }

  Future<void> addFriend(String userId, String friendId) async {
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayUnion([friendId])
    });
    await _firestore.collection('users').doc(friendId).update({
      'friends': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> removeFriend(String userId, String friendId) async {
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.arrayRemove([friendId])
    });
    await _firestore.collection('users').doc(friendId).update({
      'friends': FieldValue.arrayRemove([userId])
    });
  }

  Future<void> blockUser(String userId, String blockedId) async {
    await _firestore.collection('users').doc(userId).update({
      'blocked': FieldValue.arrayUnion([blockedId])
    });
  }

  Future<void> muteUser(String userId, String mutedId) async {
    await _firestore.collection('users').doc(userId).update({
      'muted': FieldValue.arrayUnion([mutedId])
    });
  }

  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    await _firestore.collection('friendRequests').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    final receiverUser = await getUserById(receiverId);
    final receiverToken = receiverUser.token; // Ensure the token is available in UserModel

    await _notificationUtils.sendNotification(
      token: receiverToken,
      title: 'New Friend Request',
      body: 'You have a new friend request from ${senderId}.',
    );
  }

  Future<void> _sendNotification(String userId, String title, String body) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final user = UserModel.fromMap(userDoc.data()!, userId);
    final token = user.token; // Ensure the token is available in UserModel

    await _notificationUtils.sendNotification(
      token: token,
      title: title,
      body: body,
    );
  }

  Future<List<UserModel>> searchUsers(String username) async {
    final result = await _firestore.collection('users').where('username', isEqualTo: username).get();
    return result.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }
}
