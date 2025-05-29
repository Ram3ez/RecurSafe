import "package:flutter/cupertino.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:local_auth/local_auth.dart";
import "package:local_auth_ios/local_auth_ios.dart"; // For iOS specific messages
import "package:local_auth_android/local_auth_android.dart"; // For Android specific messages
import "package:recursafe/pages/master_password_page.dart"; // Import the new page
import 'dart:io' show Platform; // Import Platform
import 'package:provider/provider.dart'; // Import Provider
import 'package:recursafe/providers/document_provider.dart'; // Import DocumentProvider
import 'package:recursafe/providers/password_provider.dart'; // Import PasswordProvider
import 'package:recursafe/utils/constants.dart'; // Import AppConstants
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

        final bool authenticated = await _localAuth.authenticate(
          localizedReason:
              'Please authenticate to enable biometric login for RecurSafe.',
          authMessages: const <AuthMessages>[
            AndroidAuthMessages(
              signInTitle: 'RecurSafe Biometric Login',
              cancelButton: 'Cancel',
            ),
            IOSAuthMessages(
              cancelButton: 'Cancel',
            ),
          ],
          options: AuthenticationOptions(
            stickyAuth: true, // Keep auth session active if app is backgrounded
            // Windows doesn't support biometricOnly: true, it will use available Windows Hello methods.
            biometricOnly: !Platform.isWindows,
          ),
        );

        if (authenticated) {
          await _secureStorage.write(
            key: AppConstants.biometricEnabledKey,
            value: 'true',
          );
          if (mounted) setState(() => _biometricsEnabled = true);
          if (!mounted) return;
          await DialogUtils.showInfoDialog(
            context,
            'Success',
            'Biometric authentication enabled.',
          );
        } else {
          if (mounted) setState(() => _biometricsEnabled = false);
          if (!mounted) return;
          await DialogUtils.showInfoDialog(
            context,
            'Authentication Failed',
            'Could not enable biometrics.',
          );
        }
      } catch (e) {
        print("Error enabling biometrics: $e");
        if (mounted) setState(() => _biometricsEnabled = false);
        if (!mounted) return;
        await DialogUtils.showInfoDialog(
          context,
          'Error',
          'An error occurred: $e',
        );
      }
    } else {
      // Disabling biometrics
      // First, require authentication to disable
      try {
        final bool authenticated = await _localAuth.authenticate(
          localizedReason:
              'Please authenticate to disable biometric login for RecurSafe.',
          authMessages: const <AuthMessages>[
            AndroidAuthMessages(
              signInTitle: 'RecurSafe Biometric Confirmation',
              cancelButton: 'Cancel',
            ),
            IOSAuthMessages(
              cancelButton: 'Cancel',
            ),
          ],
          options: AuthenticationOptions(
            stickyAuth: true,
            biometricOnly:
                !Platform.isWindows, // Adhere to platform capabilities
          ),
        );

        if (!mounted) return;

        if (authenticated) {
          await _secureStorage.delete(key: AppConstants.biometricEnabledKey);
          if (mounted) setState(() => _biometricsEnabled = false);
          await DialogUtils.showInfoDialog(
            context,
            'Success',
            'Biometric authentication disabled.',
          );
        } else {
          // Authentication failed, do not disable biometrics
          await DialogUtils.showInfoDialog(
            context,
            'Authentication Failed',
            'Biometric authentication was not disabled.',
          );
          // No change to _biometricsEnabled state here, as it wasn't disabled.
        }
      } catch (e) {
        print("Error during biometric check for disabling: $e");
        if (!mounted) return;
        await DialogUtils.showInfoDialog(
          context,
          'Error',
          'An error occurred while trying to disable biometrics. $e',
        );
      }
    }
  }

  Future<void> _handleClearAll(
    BuildContext context,
    String itemType,
    Future<void> Function() clearAction,
  ) async {
    // Step 1: Confirmation Dialog
    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'Clear All $itemType?',
      content:
          'Are you sure you want to delete all $itemType? This action cannot be undone.',
      confirmActionText: 'Clear All',
      onConfirm: () async {
        // Step 2: Biometric Authentication
        try {
          final bool authenticated = await _localAuth.authenticate(
            localizedReason: 'Please authenticate to clear all $itemType.',
            authMessages: const <AuthMessages>[
              AndroidAuthMessages(
                signInTitle: 'RecurSafe Clear Data',
                cancelButton: 'Cancel',
              ),
              IOSAuthMessages(
                cancelButton: 'Cancel',
              ),
            ],
            options: AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: !Platform.isWindows,
            ),
          );

          if (!mounted) return;

          if (authenticated) {
            // Step 3: Provider Action
            await clearAction();
            DialogUtils.showInfoDialog(
              context,
              'Success',
              'All $itemType have been cleared.',
            );
          } else {
            DialogUtils.showInfoDialog(
              context,
              'Authentication Failed',
              'Could not clear $itemType.',
            );
          }
        } catch (e) {
          DialogUtils.showInfoDialog(context, 'Error', 'An error occurred: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(largeTitle: Text("Settings")),
      child: _isLoadingBiometricPreference
          ? Center(child: CupertinoActivityIndicator())
          : ListView(
              children: <Widget>[
                SizedBox(
                  height: 40,
                ),
                CupertinoListSection.insetGrouped(
                  header: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Security'),
                  ),
                  children: <CupertinoListTile>[
                    CupertinoListTile.notched(
                      title: Text('Master Password'),
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
                      title: Text('Enable Biometrics'),
                      leading: Icon(
                        CupertinoIcons.lock_rotation,
                      ), // Or CupertinoIcons.hand_raised_fill / faceid
                      trailing: CupertinoSwitch(
                        value: _biometricsEnabled,
                        onChanged: _toggleBiometrics,
                      ),
                    ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  header: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Data Management'),
                  ),
                  children: <CupertinoListTile>[
                    CupertinoListTile.notched(
                      title: Text(
                        'Clear All Documents',
                        style: TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                      leading: Icon(
                        CupertinoIcons.trash_fill,
                        color: CupertinoColors.destructiveRed,
                      ),
                      onTap: () {
                        _handleClearAll(
                          context,
                          "Documents",
                          context.read<DocumentProvider>().clearAllDocuments,
                        );
                      },
                    ),
                    CupertinoListTile.notched(
                      title: Text(
                        'Clear All Passwords',
                        style: TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                      leading: Icon(
                        CupertinoIcons.trash_slash_fill,
                        color: CupertinoColors.destructiveRed,
                      ),
                      onTap: () {
                        _handleClearAll(
                          context,
                          "Passwords",
                          context.read<PasswordProvider>().clearAllPasswords,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
