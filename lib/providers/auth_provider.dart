import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:privy_chat/utils/encryption_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user_model.dart';
import 'package:privy_chat/screens/home.dart';
import 'package:privy_chat/screens/login.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _userModel;
  final GlobalKey<NavigatorState> navigatorKey;

  UserModel? get userModel => _userModel;

  AuthProvider(this.navigatorKey) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _userModel = null;
      navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (_) => const Login()),
      );
    } else {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          // Generate key pair if not exists
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

          // Check if email is verified
          if (!user.emailVerified) {
            await user.sendEmailVerification();
            Fluttertoast.showToast(
              msg: "Verification email sent. Please check your inbox.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
            navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(builder: (_) => const Login()),
            );
          } else {
            // Update database when email verification is successful
            if (!userDoc.data()!['emailVerified']) {
              await _firestore.collection('users').doc(user.uid).update({
                'emailVerified': true,
                'verifiedAt': FieldValue.serverTimestamp(),
              });
              Fluttertoast.showToast(
                msg: "Email verified successfully.",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
            }
            navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(builder: (_) =>  HomeScreen()),
            );
          }
        } else {
          // Handle case where user doc doesn't exist (optional)
          await signOut();
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'too-many-requests') {
          Fluttertoast.showToast(
            msg: "Too many requests. Please try again later.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Authentication error: ${e.message}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'An unexpected error occurred: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Fluttertoast.showToast(
        msg: "Signed in successfully.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: 'Sign-in error: ${e.message}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      throw e.toString();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      throw e.toString();
    }
  }

  Future<void> signUp(String username, String email, String password, {String? profileUrl}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'profileUrl': profileUrl,
        'publicKey': null,
        'privateKey': null,
        'token': null, // Initially, the token is null
        'emailVerified': false, // Default to false until email is verified
      });

      await userCredential.user!.sendEmailVerification();
      Fluttertoast.showToast(
        msg: "Verification email sent. Please check your inbox.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      await signOut(); // Log the user out after signing up to verify email
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: 'Sign-up error: ${e.message}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      throw e.toString();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (_) => const Login()),
      );
      Fluttertoast.showToast(
        msg: "Signed out successfully.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Sign-out error: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      throw e.toString();
    }
  }
}
