// lib/screens/login.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:provider/provider.dart';
import 'package:secure_flutter_chat/constant/active_constant.dart';
import 'package:secure_flutter_chat/providers/auth_provider.dart';
import 'package:secure_flutter_chat/screens/register.dart';
// import 'package:secure_flutter_chat/providers/auth_provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool visibility = false;
  bool actionLoading = false;
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        actionLoading = true;
      });
      try {
        await Provider.of<AuthProvider>(context, listen: false).signIn(
          emailController.text,
          passwordController.text,
        );
      } catch (error) {
        // Handle error
      } finally {
        if (mounted) {
          setState(() {
            actionLoading = false;
          });
        }
      }
    }
  }

  void visiblePassword() {
    setState(() {
      visibility = !visibility;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: activeColors.primaryDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Sign In",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: formKey,
                child: Column(
                  children: <Widget>[
                    buildTextField("Email", emailController, false),
                    const SizedBox(height: 20),
                    buildTextField("Password", passwordController, true),
                    const SizedBox(height: 30),
                    buildLoginButton(),
                    const SizedBox(height: 20),
                    buildRegisterText(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          validator: (value) {
            if (value!.isEmpty) {
              return '$label is required';
            }
            return null;
          },
          obscureText: isPassword ? !visibility : false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            hintText: 'Type your $label',
            hintStyle: const TextStyle(
              color: Colors.white70,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent, width: 0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.deepPurple, width: 1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: visiblePassword,
                    icon: Icon(
                      visibility ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget buildLoginButton() {
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
        gradient: LinearGradient(
          colors: [activeColors.primaryDark, activeColors.secondaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: submit,
        child: Text(
          actionLoading ? 'Loading..' : 'Login',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildRegisterText(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
        );
      },
      child: const Text(
        'Don\'t have an account? Register',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
