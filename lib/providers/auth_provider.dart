import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:secure_flutter_chat/utils/encryption_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:secure_flutter_chat/screens/home.dart';
import 'package:secure_flutter_chat/screens/login.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  UserModel? _userModel;
  final GlobalKey<NavigatorState> navigatorKey;

  UserModel? get userModel => _userModel;

  AuthProvider(this.navigatorKey) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _userModel = null;
      _navigateToLogin();
    } else {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        _userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (_userModel!.privateKey == null || _userModel!.publicKey == null) {
          final keyPair = await EncryptionUtils.generateKeyPair();
          final publicKeyPem = EncryptionUtils.encodePublicKeyToPem(keyPair.publicKey);
          final privateKeyPem = EncryptionUtils.encodePrivateKeyToPem(keyPair.privateKey);

          await _firestore.collection('users').doc(user.uid).update({
            'publicKey': publicKeyPem,
            'privateKey': privateKeyPem,
          });

          _userModel!.publicKey = publicKeyPem;
          _userModel!.privateKey = privateKeyPem;
        }

        _navigateToHome();
      } catch (e) {
        // Handle errors if needed
        print('Error during auth state change: $e');
      }
    }
    notifyListeners();
  }

  Future<void> googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'username': user.displayName,
            'email': user.email,
            'profileUrl': user.photoURL,
            'publicKey': null,
            'privateKey': null,
          });
        }
      }
    } catch (e) {
      print('Error during Google sign-in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      _navigateToLogin();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  void _navigateToHome() {
    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToLogin() {
    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }
}

