import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:recursafe/utils/constants.dart';
import 'dart:io' show Platform; // Import Platform
import 'package:recursafe/utils/dialog_utils.dart';
import 'package:crypto/crypto.dart'; // Import for hashing
import 'dart:convert'; // Import for utf8 encoding

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> isBiometricAuthEnabled() async {
    final biometricPreference = await _secureStorage.read(
      key: AppConstants.biometricEnabledKey,
    );
    final bool isEnabled = biometricPreference == 'true';
    print(
      "[AuthService DEBUG] isBiometricAuthEnabled called. Key: ${AppConstants.biometricEnabledKey}, Value read: '$biometricPreference', Is enabled: $isEnabled",
    );
    return isEnabled;
  }

  Future<void> authenticateAndExecute({
    required BuildContext context,
    required String localizedReason,
    required String itemName, // e.g., document name or "action"
    required Future<void> Function() onAuthenticated,
    required Future<void> Function() onNotAuthenticated,
  }) async {
    bool biometricsWereAttempted = false;

    if (await isBiometricAuthEnabled()) {
      biometricsWereAttempted = true;
      try {
        final bool osAuthenticated = await _localAuth.authenticate(
          localizedReason: localizedReason,
          authMessages: <AuthMessages>[
            AndroidAuthMessages(
              signInTitle: 'RecurSafe Access',
              biometricHint: 'Verify identity for $itemName',
              cancelButton: 'Cancel',
            ),
            IOSAuthMessages(
              cancelButton: 'Cancel',
              goToSettingsButton: 'Settings',
              goToSettingsDescription:
                  'Biometric authentication is not set up on your device. Please either enable Touch ID or Face ID on your device.',
            ),
          ],
          options: AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: !Platform.isWindows,
          ),
        );

        if (!context.mounted) return;

        if (osAuthenticated) {
          await onAuthenticated();
          return; // Successfully authenticated with OS biometrics
        } else {
          // OS Biometrics failed or were cancelled by user.
          // Fall through to master password prompt.
          // Optionally, show a message that biometrics failed if you want to be explicit.
          // await DialogUtils.showInfoDialog(context, 'Biometric Failed', 'Biometric/PIN authentication failed. Please try your master password.');
        }
      } catch (e) {
        print("Error during OS authentication: $e");
        if (!context.mounted) return;
        // Error during OS auth, fall through to master password.
        // You might want to show a more specific error dialog here if e is informative.
        // await DialogUtils.showInfoDialog(context, 'Biometric Error', 'An error occurred with biometric/PIN authentication. Please try your master password.');
      }
    }

    // If biometrics are not enabled, or if they were attempted and failed/errored:
    // Proceed to Master Password Authentication
    await _authenticateWithMasterPassword(
      context: context,
      localizedReason: localizedReason, // Pass the original localizedReason
      itemName: itemName,
      onAuthenticated: onAuthenticated,
      onNotAuthenticated: onNotAuthenticated,
      biometricsAttemptedMessage: biometricsWereAttempted
          ? 'Biometric/PIN authentication failed or was cancelled.'
          : null,
    );
  }

  // IMPORTANT: This hashing function MUST match the one used when setting the master password.
  // If you use a salt, it must also be handled identically.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Encode password to bytes
    final digest = sha256.convert(bytes); // Hash using SHA-256
    return digest.toString(); // Return hex string representation of the hash
  }

  Future<void> _authenticateWithMasterPassword({
    required BuildContext context,
    required String localizedReason, // Add localizedReason parameter
    required String itemName,
    required Future<void> Function() onAuthenticated,
    required Future<void> Function() onNotAuthenticated,
    String? biometricsAttemptedMessage,
  }) async {
    final String? enteredPassword = await DialogUtils.showTextInputDialog(
      context: context,
      title: 'Master Password Required',
      message:
          biometricsAttemptedMessage ??
          localizedReason, // Use localizedReason if biometrics weren't attempted
      placeholder: 'Master Password',
      confirmActionText: 'Unlock',
    );

    if (!context.mounted) return;

    if (enteredPassword == null || enteredPassword.isEmpty) {
      // User cancelled or entered nothing
      await DialogUtils.showInfoDialog(
        context,
        'Authentication Cancelled',
        'Master password entry was cancelled.',
      );
      await onNotAuthenticated();
      return;
    }

    final storedMasterPassword = await _secureStorage.read(
      key: AppConstants.masterPasswordKey,
    );

    print(
      "[AuthService DEBUG] _authenticateWithMasterPassword: Stored master password read for key '${AppConstants.masterPasswordKey}': '$storedMasterPassword'",
    );

    if (storedMasterPassword == null) {
      // This case should ideally not happen if master password setup is enforced.
      await DialogUtils.showInfoDialog(
        context,
        'Error',
        'Master password not set. Please set it in settings.',
      );
      await onNotAuthenticated();
      return;
    }

    final hashedEnteredPassword = _hashPassword(enteredPassword);

    if (hashedEnteredPassword == storedMasterPassword) {
      await onAuthenticated();
    } else {
      await DialogUtils.showInfoDialog(
        context,
        'Authentication Failed',
        'Incorrect master password.',
      );
      await onNotAuthenticated();
    }
  }
}
