import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'signup_page.dart';
import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService service = AuthService();
  final TextEditingController loginEmail = TextEditingController();
  final TextEditingController loginPwd = TextEditingController();

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void login() async {
    if (loginEmail.text.isEmpty) {
      showMsg("Insert Email");
      return;
    }
    if (loginPwd.text.isEmpty) {
      showMsg("Insert Password");
      return;
    }

    try {
      await service.login(loginEmail.text, loginPwd.text);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMsg("No user found for that email.");
      } else if (e.code == 'wrong-password') {
        showMsg("Wrong password provided.");
      } else {
        showMsg("Error: ${e.message}");
      }
    } catch (e) {
      showMsg("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: loginEmail,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: loginPwd,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                );
              },
              child: const Text("Forgot Password?"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't you have an account ?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: const Text("Signup"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}