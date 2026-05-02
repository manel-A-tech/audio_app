import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:just_audio/just_audio.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AudioPlayer _player = AudioPlayer();

  Future<bool> authenticateWithFingerprint(BuildContext context) async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity with fingerprint',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _playSuccessSound();
      }

      return authenticated;
    } catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      await _player.setAsset('assets/sounds/success.mp3');
      await _player.play();
      await Future.delayed(const Duration(seconds: 2));
      await _player.stop();
    } catch (e) {
      print('Could not play sound: $e');
    }
  }
}