import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:privy_chat/providers/auth_provider.dart';
import 'package:privy_chat/providers/theme_provider.dart';
import 'package:privy_chat/screens/register.dart';
import '../constant/app_theme.dart'; // Import the AppTheme class

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode; // Determine if dark mode is enabled

    final theme = isDarkMode ? AppTheme().dark : AppTheme().light; // Use AppTheme based on the mode

    // print({"theme data":theme.buttonTheme});

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sign In",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: formKey,
                child: Column(
                  children: <Widget>[
                    buildTextField("Email", emailController, false, theme),
                    const SizedBox(height: 20),
                    buildTextField("Password", passwordController, true, theme),
                    const SizedBox(height: 30),
                    buildLoginButton(theme),
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

  Widget buildTextField(String label, TextEditingController controller, bool isPassword, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
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
            fillColor: theme.inputDecorationTheme.fillColor,
            hintText: 'Type your $label',
            hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent, width: 0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent, width: 0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.primaryColor, width: 1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: visiblePassword,
                    icon: Icon(
                      visibility ? Icons.visibility_off : Icons.visibility,
                      color: theme.iconTheme.color,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget buildLoginButton(ThemeData theme) {
    return
     Container(
      decoration: BoxDecoration(
        // boxShadow: [
        //   BoxShadow(
        //     color: theme.iconTheme.color!.withOpacity(0.2),
        //     spreadRadius: 2,
        //     blurRadius: 5,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
        // gradient: LinearGradient(
        //   colors: [theme.primaryColor, theme.colorScheme.secondary],
        //   begin: Alignment.centerLeft,
        //   end: Alignment.centerRight,
        // ),
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        foregroundColor: Colors.white, // Set button text color
        backgroundColor: theme.primaryColor, // Remove default background color
      ),
      onPressed: submit,
      child: Text(
        actionLoading ? 'Loading..' : 'Login',
        style: theme.textTheme.labelLarge?.copyWith(
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
