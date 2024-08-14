class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profileUrl; // Add profile URL (optional)
  String? publicKey;
  String? privateKey;
  final String token;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileUrl,
    this.privateKey,
    this.publicKey,
    required this.token
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileUrl: data['profileUrl'] ?? '',
      publicKey: data['publicKey'],
      privateKey: data['privateKey'],
      token: data['token'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'profileUrl': profileUrl,
      'publicKey': publicKey,
      'token': token
    };
  }
}
