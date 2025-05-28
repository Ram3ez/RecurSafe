import "package:flutter/cupertino.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:local_auth/local_auth.dart";
import "package:local_auth_ios/local_auth_ios.dart"; // For iOS specific messages
import "package:local_auth_android/local_auth_android.dart"; // For Android specific messages
import "package:recursafe/pages/master_password_page.dart"; // Import the new page

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _biometricEnabledKey = 'biometric_auth_enabled';

  bool _biometricsEnabled = false;
  bool _isLoadingBiometricPreference = true;

  // Placeholder for showing a confirmation dialog
  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Confirm'),
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoDialog(String title, String content) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    try {
      final storedPreference = await _secureStorage.read(
        key: _biometricEnabledKey,
      );
      if (mounted) {
        setState(() {
          _biometricsEnabled = storedPreference == 'true';
          _isLoadingBiometricPreference = false;
        });
      }
    } catch (e) {
      print("Error loading biometric preference: $e");
      if (mounted) {
        setState(() {
          _biometricsEnabled = false; // Assume disabled on error
          _isLoadingBiometricPreference = false; // Stop loading
        });
      }
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    if (enable) {
      try {
        final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final bool isDeviceSupported = await _localAuth.isDeviceSupported();

        if (!isDeviceSupported || !canCheckBiometrics) {
          await _showInfoDialog(
            'Biometrics Not Supported',
            'Your device does not support biometric authentication or it is not configured.',
          );
          if (mounted) setState(() => _biometricsEnabled = false);
          return;
        }

        final List<BiometricType> availableBiometrics = await _localAuth
            .getAvailableBiometrics();

        if (availableBiometrics.isEmpty) {
          await _showInfoDialog(
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
          options: const AuthenticationOptions(
            stickyAuth: true, // Keep auth session active if app is backgrounded
            biometricOnly: true, // Only allow biometrics, no device PIN/Pattern
          ),
        );

        if (authenticated) {
          await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
          if (mounted) setState(() => _biometricsEnabled = true);
          await _showInfoDialog('Success', 'Biometric authentication enabled.');
        } else {
          if (mounted) setState(() => _biometricsEnabled = false);
          await _showInfoDialog(
            'Authentication Failed or Cancelled',
            'Could not enable biometrics.',
          );
        }
      } catch (e) {
        print("Error enabling biometrics: $e");
        if (mounted) setState(() => _biometricsEnabled = false);
        await _showInfoDialog('Error', 'An error occurred: $e');
      }
    } else {
      // Disabling biometrics
      await _secureStorage.delete(key: _biometricEnabledKey);
      if (mounted) setState(() => _biometricsEnabled = false);
      await _showInfoDialog('Success', 'Biometric authentication disabled.');
    }
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
                        value:
                            _biometricsEnabled ??
                            false, // Safeguard against null
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
                        _showConfirmationDialog(
                          title: 'Clear All Documents?',
                          content:
                              'Are you sure you want to delete all documents? This action cannot be undone.',
                          onConfirm: () {
                            // TODO: Implement clear all documents logic
                            print('Clear All Documents confirmed');
                          },
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
                        _showConfirmationDialog(
                          title: 'Clear All Passwords?',
                          content:
                              'Are you sure you want to delete all passwords? This action cannot be undone.',
                          onConfirm: () {
                            // TODO: Implement clear all passwords logic
                            print('Clear All Passwords confirmed');
                          },
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
