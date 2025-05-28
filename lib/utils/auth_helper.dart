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
    // Use a GlobalKey to access the state of _MasterPasswordDialogContent
    // if needed, though for this simple case, passing a callback is cleaner.
    // For returning the result, we'll rely on the value returned by showCupertinoDialog.
    final bool? isAuthenticated = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return _MasterPasswordDialogContent(
          passwordController: passwordController,
          storedHash: storedHash,
          hashPasswordCallback: _hashPassword,
        );
      },
    );

    passwordController
        .dispose(); // Dispose the controller after the dialog is closed
    return isAuthenticated ??
        false; // Return true if authenticated, false otherwise (including null)
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

// New StatefulWidget for the dialog content
class _MasterPasswordDialogContent extends StatefulWidget {
  final TextEditingController passwordController;
  final String storedHash;
  final String Function(String) hashPasswordCallback;

  const _MasterPasswordDialogContent({
    required this.passwordController,
    required this.storedHash,
    required this.hashPasswordCallback,
  });

  @override
  State<_MasterPasswordDialogContent> createState() =>
      _MasterPasswordDialogContentState();
}

class _MasterPasswordDialogContentState
    extends State<_MasterPasswordDialogContent> {
  String? _errorMessage;

  void _authenticate() {
    final enteredPasswordHash = widget.hashPasswordCallback(
      widget.passwordController.text,
    );
    if (enteredPasswordHash == widget.storedHash) {
      Navigator.of(context).pop(true); // Pop with true for success
    } else {
      setState(() {
        _errorMessage = 'Incorrect master password. Please try again.';
        widget.passwordController.clear(); // Clear the text field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Enter Master Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: CupertinoTextField(
              controller: widget.passwordController,
              placeholder: 'Master Password',
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autofocus: true,
              onSubmitted: (_) =>
                  _authenticate(), // Allow submitting with enter key
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: CupertinoColors.destructiveRed.resolveFrom(context),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false); // Pop with false for cancellation
          },
        ),
        CupertinoDialogAction(
          child: const Text('Authenticate'),
          isDefaultAction: true,
          onPressed: _authenticate,
        ),
      ],
    );
  }
}
