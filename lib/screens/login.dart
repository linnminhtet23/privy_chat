import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_flutter_chat/constant/active_constant.dart';
import 'package:secure_flutter_chat/providers/auth_provider.dart';
import 'package:secure_flutter_chat/screens/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool actionLoading = false;

  Future<void> googleSignIn() async {
    if (!mounted) return;
    setState(() {
      actionLoading = true;
    });
    try {
      await Provider.of<AuthProvider>(context, listen: false).googleSignIn();
      //  if (mounted) {
      
      //  }
    } catch (error) {
      // Handle error
    } finally {
      
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
         Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()), 
      ); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: activeColors.primaryDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              buildGoogleSignInButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGoogleSignInButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: googleSignIn,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.login,
              color: Colors.black,
            ),
            const SizedBox(width: 10),
            Text(
              actionLoading ? 'Loading...' : 'Sign in with Google',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
