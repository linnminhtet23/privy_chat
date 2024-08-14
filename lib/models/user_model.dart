class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profileUrl; // Add profile URL (optional)
  String? publicKey;
  String? privateKey;
  final String? token;
  final bool emailVerified; // Add emailVerified field

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileUrl,
    this.privateKey,
    this.publicKey,
    this.token,
    this.emailVerified = false, // Default value for emailVerified
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileUrl: data['profileUrl'],
      publicKey: data['publicKey'],
      privateKey: data['privateKey'],
      token: data['token'],
      emailVerified: data['emailVerified'] ?? false, // Default to false if not present
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'profileUrl': profileUrl,
      'publicKey': publicKey,
      'token': token,
      'emailVerified': emailVerified, // Add emailVerified to map
    };
  }
}
