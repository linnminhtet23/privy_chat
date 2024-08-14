import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_flutter_chat/constant/active_constant.dart';
import 'package:secure_flutter_chat/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool visibility = false;
  bool actionLoading = false;
  // bool isMounted = false;

    @override
  void initState() {
    super.initState();
    // isMounted = true;
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    // isMounted=false;
    super.dispose();
  }

  void visiblePassword() {
    setState(() {
      visibility = !visibility;
    });
  }

  Future<void> submit() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      // Print the controller.text values
      // print('Username: ${usernameController.text}');
      // print('Email: ${emailController.text}');
      // print('Password: ${passwordController.text}');

        await Provider.of<AuthProvider>(context, listen: false).signUp(
          usernameController.text,
          emailController.text,
          passwordController.text,
          profileUrl: null,
        );

      // Implement your registration logic here
      // if(mounted){
      // Navigator.of(context).pop();
      // }
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: activeColors.primaryDark,
      appBar: AppBar(
        // title: const Text('Register'),
        backgroundColor: activeColors.primaryDark,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Register",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                buildTextField("Username", usernameController, false, isUsername: true),
                const SizedBox(height: 20),
                buildTextField("Email", emailController, false),
                const SizedBox(height: 20),
                buildTextField("Password", passwordController, true),
                const SizedBox(height: 30),
                buildRegisterButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, bool isPassword, {bool isUsername = false}) {
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
            prefixIcon: isUsername
                ? const Icon(
                    Icons.alternate_email,
                    color: Colors.white70,
                  )
                : null,
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

  Widget buildRegisterButton() {
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
          actionLoading ? 'Loading..' : 'Register',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
