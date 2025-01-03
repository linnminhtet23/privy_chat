import 'package:privy_chat/constants.dart';

class UserModel {
  String uid;
  String name;
  String email;
  String password;
  String image;
  String token;
  String aboutMe;
  String lastSeen;
  String createdAt;
  bool isOnline;
  String? publicKey;
  String? privateKey;
  List<String> friendsUIDs;
  List<String> friendRequestsUIDs;
  List<String> sentFriendRequestsUIDs;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.image,
    required this.token,
    required this.aboutMe,
    required this.lastSeen,
    required this.createdAt,
    required this.isOnline,
    this.privateKey,
    this.publicKey,
    required this.friendsUIDs,
    required this.friendRequestsUIDs,
    required this.sentFriendRequestsUIDs,
  });

  // from map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constants.uid] ?? '',
      name: map[Constants.name] ?? '',
      email: map[Constants.email] ?? '',
      password: map[Constants.password] ?? '',
      image: map[Constants.image] ?? '',
      token: map[Constants.token] ?? '',
      aboutMe: map[Constants.aboutMe] ?? '',
      lastSeen: map[Constants.lastSeen] ?? '',
      createdAt: map[Constants.createdAt] ?? '',
      isOnline: map[Constants.isOnline] ?? false,
      publicKey: map[Constants.publicKey] ?? null,
      privateKey: map[Constants.privateKey] ?? null,

      friendsUIDs: List<String>.from(map[Constants.friendsUIDs] ?? []),
      friendRequestsUIDs:
      List<String>.from(map[Constants.friendRequestsUIDs] ?? []),
      sentFriendRequestsUIDs:
      List<String>.from(map[Constants.sentFriendRequestsUIDs] ?? []),
    );
  }

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.uid: uid,
      Constants.name: name,
      Constants.email: email,
      // Constants.password: password,
      Constants.image: image,
      Constants.token: token,
      Constants.aboutMe: aboutMe,
      Constants.lastSeen: lastSeen,
      Constants.createdAt: createdAt,
      Constants.isOnline: isOnline,
      Constants.publicKey: publicKey,
      Constants.privateKey: privateKey,
      Constants.friendsUIDs: friendsUIDs,
      Constants.friendRequestsUIDs: friendRequestsUIDs,
      Constants.sentFriendRequestsUIDs: sentFriendRequestsUIDs,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode {
    return uid.hashCode;
  }
}
