/*
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'biometric_service.dart';
import 'app_localizations.dart';
import 'language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'Tarteel',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BiometricAuthWrapper(key: ValueKey(languageProvider.locale.languageCode)),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometric());
  }

  Future<void> _checkBiometric() async {
    final ok = await _biometricService.authenticateWithFingerprint(context);
    if (mounted) {
      setState(() {
        _isAuthenticated = ok;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80),
              const SizedBox(height: 20),
              Text(l.authRequired),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkBiometric,
                child: Text(l.tryAgain),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data == null ? const LoginPage() : const HomePage();
      },
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'biometric_service.dart';
import 'app_localizations.dart';
import 'language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'Serene',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Style snackbars globally as soft rounded pills in muted purple
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF7C6FA0),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          behavior: SnackBarBehavior.floating,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 4,
        ),
      ),
      home: BiometricAuthWrapper(key: ValueKey(languageProvider.locale.languageCode)),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometric());
  }

  Future<void> _checkBiometric() async {
    final ok = await _biometricService.authenticateWithFingerprint(context);
    if (mounted) {
      setState(() {
        _isAuthenticated = ok;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEDEAE6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7C6FA0))),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFEDEAE6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Color(0xFF7C6FA0)),
              const SizedBox(height: 20),
              Text(l.authRequired,
                  style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6FA0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                onPressed: _checkBiometric,
                child: Text(l.tryAgain,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
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
            backgroundColor: Color(0xFFEDEAE6),
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFF7C6FA0))),
          );
        }
        return snapshot.data == null ? const LoginPage() : const HomePage();
      },
    );
  }
}