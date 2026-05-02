import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'biometric_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BiometricAuthWrapper(),
    );
  }
}

class BiometricAuthWrapper extends StatefulWidget {
  const BiometricAuthWrapper({super.key});

  @override
  State<BiometricAuthWrapper> createState() => _BiometricAuthWrapperState();
}

class _BiometricAuthWrapperState extends State<BiometricAuthWrapper> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  final BiometricService _biometricService = BiometricService();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometric();
    });
  }

  Future<void> _checkBiometric() async {
    final isAuthenticated = await _biometricService.authenticateWithFingerprint(context);
    setState(() {
      _isAuthenticated = isAuthenticated;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80),
              const SizedBox(height: 20),
              const Text('Authentication required'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkBiometric,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null ? const LoginPage() : const HomePage();
      },
    );
  }
}