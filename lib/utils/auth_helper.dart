import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:local_auth_ios/types/auth_messages_ios.dart';

class AuthHelper {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _masterPasswordKey = 'master_password_hash';
  static const String _biometricEnabledKey = 'biometric_auth_enabled';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // data being hashed
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> authenticate(BuildContext context) async {
    // 1. Check if biometrics is enabled
    final biometricEnabled =
        await _secureStorage.read(key: _biometricEnabledKey) == 'true';

    if (biometricEnabled) {
      try {
        final bool canAuthenticateWithBiometrics =
            await _localAuth.canCheckBiometrics;
        final bool isDeviceSupported = await _localAuth.isDeviceSupported();
        final List<BiometricType> availableBiometrics = await _localAuth
            .getAvailableBiometrics();

        if (canAuthenticateWithBiometrics &&
            isDeviceSupported &&
            availableBiometrics.isNotEmpty) {
          final bool didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Authenticate to access this locked item.',
            authMessages: const <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: 'RecurSafe Authentication',
                cancelButton: 'Cancel',
              ),
              IOSAuthMessages(
                // Add iOS specific messages
                cancelButton: 'Cancel',
              ),
            ],
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
          if (didAuthenticate) {
            return true; // Biometric authentication successful
          }
        }
      } catch (e) {
        print("Error during biometric authentication: $e");
        // Fallback to master password if biometrics fails unexpectedly
      }
    }

    // 2. Fallback to Master Password if biometrics is not enabled, not available, or failed
    final masterPasswordHash = await _secureStorage.read(
      key: _masterPasswordKey,
    );
    if (masterPasswordHash != null) {
      // Prompt for master password
      return await _promptForMasterPassword(context, masterPasswordHash);
    }

    // No biometrics enabled and no master password set - locking a file should probably
    // require a master password to be set first. If we reach here, it means
    // authentication is required but no method is available.
    await _showInfoDialog(
      context,
      'Authentication Required',
      'Please set a Master Password or enable Biometrics in Settings.',
    );
    return false;
  }

  Future<bool> _promptForMasterPassword(
    BuildContext context,
    String storedHash,
  ) async {
    TextEditingController passwordController = TextEditingController();
    bool isAuthenticated = false;

    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        // Use dialogContext
        title: const Text('Enter Master Password'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: passwordController,
            placeholder: 'Master Password',
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            autofocus: true,
          ),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Use dialogContext
            },
          ),
          CupertinoDialogAction(
            child: const Text('Authenticate'),
            isDefaultAction: true,
            onPressed: () {
              final enteredPasswordHash = _hashPassword(
                passwordController.text,
              );
              if (enteredPasswordHash == storedHash) {
                isAuthenticated = true;
                Navigator.of(dialogContext).pop(); // Use dialogContext
              } else {
                // A better UX would be to show an error message in the dialog itself
                // For now, we'll just print and let the user try again or cancel
                print("Incorrect master password");
                // Optionally, show an error within the dialog or a new dialog
                // For simplicity, this example just closes on incorrect attempt after printing.
                // To keep the dialog open and show an error, you'd need a StatefulWidget for the dialog content.
              }
            },
          ),
        ],
      ),
    );

    passwordController.dispose();
    return isAuthenticated;
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        // Use dialogContext
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Use dialogContext
            },
          ),
        ],
      ),
    );
  }
}
