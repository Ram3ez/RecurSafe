import "package:flutter/cupertino.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:local_auth/local_auth.dart";
import "package:local_auth_ios/local_auth_ios.dart"; // For iOS specific messages
import "package:local_auth_android/local_auth_android.dart"; // For Android specific messages
import "package:recursafe/pages/master_password_page.dart"; // Import the new page
import 'package:flutter/services.dart'; // Import for SystemNavigator
import 'dart:io' show Platform; // Import Platform
import 'package:provider/provider.dart'; // Import Provider
import 'package:recursafe/providers/document_provider.dart'; // Import DocumentProvider
import 'package:recursafe/providers/password_provider.dart'; // Import PasswordProvider
import 'package:recursafe/utils/constants.dart'; // Import AppConstants
import 'package:recursafe/services/notification_service.dart'; // Import NotificationService
import 'package:recursafe/utils/crypto_utils.dart'; // Import for hashPassword
import 'package:recursafe/notifiers/app_reset_notifier.dart'; // Import AppResetNotifier
import 'package:recursafe/utils/dialog_utils.dart'; // Import DialogUtils

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  // static const String _biometricEnabledKey = 'biometric_auth_enabled'; // Replaced by AppConstants

  bool _biometricsEnabled = false;
  bool _isLoadingBiometricPreference = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  // Helper method for performing biometric authentication
  Future<bool> _performBiometricAuth({
    required String localizedReason,
    String androidSignInTitle = 'RecurSafe Authentication',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: androidSignInTitle,
            cancelButton: 'Cancel',
          ),
          const IOSAuthMessages(
            cancelButton: 'Cancel',
          ),
        ],
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !Platform.isWindows,
        ),
      );
    } catch (e) {
      print("Error during biometric authentication: $e");
      if (mounted) {
        // Use a more generic error message for the user
        await DialogUtils.showErrorDialog(
          context,
          'An authentication error occurred. Please try again.',
        );
      }
      return false;
    }
  }

  Future<void> _loadBiometricPreference() async {
    final storedPreference = await _secureStorage.read(
      key: AppConstants.biometricEnabledKey,
    );
    if (mounted) {
      setState(() {
        _biometricsEnabled = storedPreference == 'true';
        _isLoadingBiometricPreference = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    if (enable) {
      try {
        final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final bool isDeviceSupported = await _localAuth.isDeviceSupported();

        if (!isDeviceSupported || !canCheckBiometrics) {
          if (!mounted) return;
          await DialogUtils.showInfoDialog(
            context,
            'Biometrics Not Supported',
            'Your device does not support biometric authentication or it is not configured.',
          );
          if (mounted) setState(() => _biometricsEnabled = false);
          return;
        }

        final List<BiometricType> availableBiometrics = await _localAuth
            .getAvailableBiometrics();

        if (availableBiometrics.isEmpty) {
          if (!mounted) return;
          await DialogUtils.showInfoDialog(
            context,
            'No Biometrics Enrolled',
            'Please enroll biometrics in your device settings first.',
          );
          if (mounted) setState(() => _biometricsEnabled = false);
          return;
        }

        final bool authenticated = await _performBiometricAuth(
          localizedReason:
              'Please authenticate to enable biometric login for RecurSafe.',
          androidSignInTitle: 'RecurSafe Biometric Login',
        );

        if (authenticated) {
          await _secureStorage.write(
            key: AppConstants.biometricEnabledKey,
            value: 'true',
          );
          if (mounted) {
            setState(() => _biometricsEnabled = true);
            await DialogUtils.showInfoDialog(
              context,
              'Success',
              'Biometric authentication enabled.',
            );
          }
        } else {
          if (mounted) {
            setState(
              () => _biometricsEnabled = false,
            ); // Reflect enabling failed
            await DialogUtils.showInfoDialog(
              context,
              'Authentication Failed',
              'Could not enable biometrics.',
            );
          }
        }
      } catch (e) {
        print("Error enabling biometrics: $e");
        if (mounted) {
          setState(
            () => _biometricsEnabled = false,
          ); // Ensure it's off if checks/auth fail
          await DialogUtils.showErrorDialog(
            context,
            'An error occurred while enabling biometrics: $e',
          );
        }
      }
    } else {
      // Disabling biometrics
      try {
        final bool authenticated = await _performBiometricAuth(
          localizedReason:
              'Please authenticate to disable biometric login for RecurSafe.',
          androidSignInTitle: 'RecurSafe Biometric Confirmation',
        );

        if (!mounted) return;

        if (authenticated) {
          await _secureStorage.delete(key: AppConstants.biometricEnabledKey);
          if (mounted) {
            setState(() => _biometricsEnabled = false);
            await DialogUtils.showInfoDialog(
              context,
              'Success',
              'Biometric authentication disabled.',
            );
          }
        } else {
          // Authentication failed, do not disable biometrics
          await DialogUtils.showInfoDialog(
            context,
            'Authentication Failed',
            'Biometric authentication was not disabled.',
          );
          // _biometricsEnabled remains true, switch will reflect this.
        }
      } catch (e) {
        print("Error during biometric check for disabling: $e");
        if (!mounted) return;
        await DialogUtils.showErrorDialog(
          context,
          'An error occurred while trying to disable biometrics. $e',
        );
        // _biometricsEnabled remains true if an error occurred during disabling.
      }
    }
  }

  // Method to verify master password via dialog
  Future<bool> _verifyMasterPassword(BuildContext dialogParentContext) async {
    final TextEditingController passwordController = TextEditingController();
    String? dialogErrorMessage;

    final bool? success = await showCupertinoDialog<bool>(
      context: dialogParentContext,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return CupertinoAlertDialog(
              title: const Text('Enter Master Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Stretch children horizontally
                children: [
                  const SizedBox(height: 12.0), // Added padding below title
                  CupertinoTextField(
                    controller: passwordController,
                    placeholder: 'Master Password',
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.start, // Align text to the start
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 0.0,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemFill.resolveFrom(
                        stfContext,
                      ), // iOS-like text field background
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 0.0),
                      child: Icon(
                        CupertinoIcons.lock_fill,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(stfContext),
                    ), // Ensure text color adapts
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(
                        stfContext,
                      ),
                    ),
                  ),
                  if (dialogErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dialogErrorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false); // Cancelled
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Verify'),
                  onPressed: () async {
                    final enteredPassword = passwordController.text;
                    if (enteredPassword.isEmpty) {
                      stfSetState(
                        () => dialogErrorMessage = "Password cannot be empty.",
                      );
                      return;
                    }
                    final storedHash = await _secureStorage.read(
                      key: AppConstants.masterPasswordKey,
                    );
                    if (storedHash == null) {
                      print(
                        "[ERROR] SettingsPage: Master password hash not found for verification.",
                      );
                      Navigator.of(dialogContext).pop(false); // System error
                      return;
                    }
                    if (hashPassword(enteredPassword) == storedHash) {
                      Navigator.of(dialogContext).pop(true); // Success
                    } else {
                      stfSetState(
                        () => dialogErrorMessage = "Incorrect master password.",
                      );
                      passwordController.clear();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
    return success ?? false; // Treat dialog dismissal as failure
  }

  Future<void> _handleClearAll(
    String itemType,
    Future<void> Function() clearAction,
  ) async {
    // Step 1: Confirmation Dialog
    final bool? confirmed = await DialogUtils.showConfirmationDialog(
      context: this.context, // Use this.context or just context
      title: 'Clear All $itemType?',
      content:
          'Are you sure you want to delete all $itemType? This action cannot be undone.',
      confirmActionText: 'Clear All',
      isDestructiveAction: true,
    );

    if (confirmed != true || !mounted) return;

    // Step 2: Biometric Authentication
    bool authenticated = false;
    try {
      if (_biometricsEnabled) {
        authenticated = await _performBiometricAuth(
          localizedReason: 'Please authenticate to clear all $itemType.',
          androidSignInTitle: 'RecurSafe Clear Data',
        );
      } else {
        authenticated = await _verifyMasterPassword(context);
      }

      if (!mounted) return;

      if (authenticated) {
        // Step 3: Provider Action
        await clearAction();
        if (mounted) {
          DialogUtils.showInfoDialog(
            context,
            'Success',
            'All $itemType have been cleared.',
          );
        }
      } else {
        if (mounted) {
          DialogUtils.showInfoDialog(
            context,
            'Action Incomplete',
            '$itemType were not cleared as authentication was not successful or was cancelled.',
          );
        }
      }
    } catch (e) {
      // _performBiometricAuth handles its own errors by showing a dialog.
      // This catch is for errors from clearAction() or other unexpected issues.
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          'An error occurred while clearing $itemType: $e',
        );
      }
    }
  }

  Future<void> _handleResetApp() async {
    final bool? confirmed = await DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Reset App?',
      content:
          'This will permanently delete all your documents, passwords, and the master password. This action cannot be undone. The app will close after the reset.',
      confirmActionText: 'Reset App',
      isDestructiveAction: true,
    );

    if (confirmed != true || !mounted) return;

    bool authenticated = false;
    try {
      if (_biometricsEnabled) {
        authenticated = await _performBiometricAuth(
          localizedReason: 'Please authenticate to reset the app.',
          androidSignInTitle: 'RecurSafe App Reset',
        );
      } else {
        authenticated = await _verifyMasterPassword(context);
      }

      if (!mounted) return;

      if (authenticated) {
        final docProvider = Provider.of<DocumentProvider>(
          context,
          listen: false,
        );
        final passProvider = Provider.of<PasswordProvider>(
          context,
          listen: false,
        );

        await docProvider.clearAllDocuments();
        await passProvider.clearAllPasswords();
        await _secureStorage.delete(
          key: AppConstants.masterPasswordKey, // Use constant
        );
        await _secureStorage.delete(key: AppConstants.biometricEnabledKey);
        await _secureStorage.delete(
          key: AppConstants.onboardingCompleteKey, // Use constant
        );

        if (!mounted) return;

        // Send notification before closing
        await NotificationService.showSimpleNotification(
          title: 'RecurSafe App Reset',
          body: 'All app data has been successfully cleared. Setting up fresh.',
        );

        // Notify AppController to show onboarding
        Provider.of<AppResetNotifier>(context, listen: false).notifyReset();

        // SystemNavigator.pop(); // Removed: Not suitable for iOS and now handled by AppResetNotifier
      } else {
        if (!mounted) return;
        await DialogUtils.showInfoDialog(
          context,
          'Action Incomplete',
          'App reset was not completed as authentication was not successful or was cancelled.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      // _performBiometricAuth handles its own errors. This catch is for other errors.
      await DialogUtils.showErrorDialog(
        context,
        'An error occurred during the app reset process: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Determine current brightness
      backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
      // navigationBar is removed from here and placed inside CustomScrollView
      child: _isLoadingBiometricPreference
          ? Center(child: CupertinoActivityIndicator())
          : CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(
                  largeTitle: const Text("Settings"),
                ),
                // New Tile for Logo and Description
                // New Tile for Logo and Description
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    // No header for this section, or you can add one if desired
                    children: <CupertinoListTile>[
                      CupertinoListTile(
                        // Using a standard CupertinoListTile, not notched as it's not interactive
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ), // Adjust padding
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize
                              .min, // Ensure column takes minimum necessary vertical space
                          children: <Widget>[
                            Image.asset(
                              'assets/icon.png', // Make sure this path is correct
                              height: 60, // Slightly smaller for a tile
                              width: 60, // Slightly smaller for a tile
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "RecurSafe", // App Name
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .navTitleTextStyle
                                  .copyWith(
                                    // navTitleTextStyle's default color is CupertinoColors.label (adaptive),
                                    // default fontSize is ~17.0, and fontWeight is FontWeight.w600.
                                    // We're just ensuring our desired fontSize.
                                    fontSize: 18,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Your secure vault for documents and passwords, keeping your digital life organized and protected.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                // Adjusted for better readability
                                fontSize: 15, // Keep font size
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                        // No trailing or onTap as it's purely informational
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: const Text('Security'),
                    ),
                    children: <CupertinoListTile>[
                      CupertinoListTile.notched(
                        title: const Text('Master Password'),
                        leading: Icon(CupertinoIcons.lock_shield_fill),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const MasterPasswordPage(),
                            ),
                          );
                        },
                      ),
                      CupertinoListTile.notched(
                        title: const Text('Enable Biometrics'),
                        leading: const Icon(
                          CupertinoIcons.lock_rotation,
                        ), // Or CupertinoIcons.hand_raised_fill / faceid
                        trailing: CupertinoSwitch(
                          value: _biometricsEnabled,
                          onChanged: _toggleBiometrics,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: const Text('Data Management'),
                    ),
                    children: <CupertinoListTile>[
                      CupertinoListTile.notched(
                        title: const Text(
                          'Clear All Documents',
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                        leading: Icon(
                          CupertinoIcons.trash_fill,
                          color: CupertinoColors.destructiveRed,
                        ),
                        onTap: () {
                          _handleClearAll(
                            "Documents",
                            context.read<DocumentProvider>().clearAllDocuments,
                          );
                        },
                      ),
                      CupertinoListTile.notched(
                        title: const Text(
                          'Clear All Passwords',
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                        leading: Icon(
                          CupertinoIcons.trash_slash_fill,
                          color: CupertinoColors.destructiveRed,
                        ),
                        onTap: () {
                          _handleClearAll(
                            "Passwords",
                            context.read<PasswordProvider>().clearAllPasswords,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: const Text('App Management'),
                    ),
                    children: <CupertinoListTile>[
                      CupertinoListTile.notched(
                        title: const Text(
                          'Reset App',
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                        leading: Icon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          color: CupertinoColors.destructiveRed,
                        ),
                        onTap: _handleResetApp,
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ), // Add some padding at the bottom
              ],
            ),
    );
  }
}
