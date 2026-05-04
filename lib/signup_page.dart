/*import 'package:flutter/material.dart';
import 'auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService service = AuthService();

  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController confirmEmail = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  DateTime? dob;

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dob = picked;
      });
    }
  }

  void signup() async {
    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        email.text.isEmpty) {
      showMsg("Insert all fields");
      return;
    }

    if (password.text.length < 6) {
      showMsg("Weak Password, use at least 6 characters");
      return;
    }

    if (dob == null) {
      showMsg("Select date of birth");
      return;
    }

    if (!service.isValid13(dob!)) {
      showMsg("Must be 13+");
      return;
    }

    if (email.text != confirmEmail.text) {
      showMsg("Emails do not match");
      return;
    }

    if (password.text != confirmPassword.text) {
      showMsg("Passwords do not match");
      return;
    }

    try {
      await service.signup(
        firstName: firstName.text,
        lastName: lastName.text,
        dob: dob!,
        email: email.text,
        password: password.text,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showMsg("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: firstName,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            TextField(
              controller: lastName,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: confirmEmail,
              decoration: const InputDecoration(labelText: "Confirm Email"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            TextField(
              controller: confirmPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            ListTile(
              title: Text(dob == null ? "Date of Birth" : "DOB: ${dob!.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signup,
              child: const Text("Create Account"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account ?"),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Login"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'app_localizations.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService service = AuthService();

  final TextEditingController firstName       = TextEditingController();
  final TextEditingController lastName        = TextEditingController();
  final TextEditingController email           = TextEditingController();
  final TextEditingController confirmEmail    = TextEditingController();
  final TextEditingController password        = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  DateTime? dob;

  void showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => dob = picked);
  }

  void signup() async {
    final l = AppLocalizations.of(context);
    if (firstName.text.isEmpty || lastName.text.isEmpty || email.text.isEmpty) {
      showMsg(l.insertAllFields); return;
    }
    if (password.text.length < 6) { showMsg(l.weakPassword); return; }
    if (dob == null) { showMsg(l.selectDob); return; }
    if (!service.isValid13(dob!)) { showMsg(l.must13); return; }
    if (email.text != confirmEmail.text) { showMsg(l.emailsDoNotMatch); return; }
    if (password.text != confirmPassword.text) { showMsg(l.passwordsDoNotMatch); return; }

    try {
      await service.signup(
        firstName: firstName.text,
        lastName: lastName.text,
        dob: dob!,
        email: email.text,
        password: password.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMsg('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.signup)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: firstName,        decoration: InputDecoration(labelText: l.firstName)),
            TextField(controller: lastName,         decoration: InputDecoration(labelText: l.lastName)),
            TextField(controller: email,            decoration: InputDecoration(labelText: l.email)),
            TextField(controller: confirmEmail,     decoration: InputDecoration(labelText: l.confirmEmail)),
            TextField(controller: password,         obscureText: true, decoration: InputDecoration(labelText: l.password)),
            TextField(controller: confirmPassword,  obscureText: true, decoration: InputDecoration(labelText: l.confirmPassword)),
            ListTile(
              title: Text(dob == null
                  ? l.dateOfBirth
                  : '${l.dob}: ${dob!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: signup, child: Text(l.createAccount)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l.alreadyHaveAccount),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.login),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}