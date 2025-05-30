import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:recursafe/utils/crypto_utils.dart'; // Import the utility

class MasterPasswordPage extends StatefulWidget {
  const MasterPasswordPage({super.key});

  @override
  State<MasterPasswordPage> createState() => _MasterPasswordPageState();
}

class _MasterPasswordPageState extends State<MasterPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordSet = false;
  bool _isLoading = true;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  static const String _masterPasswordKey = 'master_password_hash';

  @override
  void initState() {
    super.initState();
    _checkIfPasswordIsSet();
  }

  Future<void> _checkIfPasswordIsSet() async {
    final storedHash = await _secureStorage.read(key: _masterPasswordKey);
    if (mounted) {
      setState(() {
        _isPasswordSet = storedHash != null;
        _isLoading = false;
      });
    }
  }

  Future<void> _setOrChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true); // Show loading indicator
    if (_isPasswordSet) {
      final storedHash = await _secureStorage.read(key: _masterPasswordKey);
      final oldPasswordHash = hashPassword(_oldPasswordController.text);
      if (storedHash != oldPasswordHash) {
        _showErrorDialog('Incorrect old password.');
        return;
      }
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('New passwords do not match.');
      return;
    }

    // Add password strength validation if desired
    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('New password must be at least 6 characters long.');
      return;
    }

    final newPasswordHash = hashPassword(_newPasswordController.text);
    try {
      await _secureStorage.write(
        key: _masterPasswordKey,
        value: newPasswordHash,
      );
      _showSuccessDialog();
      if (mounted) {
        setState(() {
          _isPasswordSet = true; // Update state after successful change/set
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // Hide loading indicator
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(
          _isPasswordSet
              ? 'Master password changed successfully.'
              : 'Master password set successfully.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to settings page
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String placeholder,
    bool obscureText,
    VoidCallback toggleObscure,
  ) {
    // Validator logic to be used by the FormField
    String? validator(String? value) {
      if (value == null || value.isEmpty) {
        return '$placeholder is required';
      }
      return null;
    }

    return FormField<String>(
      initialValue:
          controller.text, // Ensures FormField starts with controller's text
      validator: validator,
      builder: (FormFieldState<String> field) {
        return CupertinoFormRow(
          prefix: Icon(
            CupertinoIcons.lock,
            color: CupertinoColors.systemGrey,
            size: 20,
          ),
          error: field.hasError ? Text(field.errorText!) : null,
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            onChanged: (value) {
              field.didChange(value); // Update FormField's value for validation
            },
            suffix: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: toggleObscure, // Allows the button to be compact
              child: Icon(
                obscureText
                    ? CupertinoIcons.eye_slash_fill
                    : CupertinoIcons.eye_fill,
                color: CupertinoColors.systemGrey,
                size: 22, // Adjust size as needed
              ),
            ),
            decoration:
                null, // Uses default CupertinoTextField decoration within the row
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _isPasswordSet ? 'Change Master Password' : 'Set Master Password',
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      CupertinoFormSection.insetGrouped(
                        header: Text(
                          _isPasswordSet
                              ? 'Enter your current and new password.'
                              : 'Create a master password for the app.',
                        ),
                        children: <Widget>[
                          if (_isPasswordSet)
                            _buildPasswordField(
                              _oldPasswordController,
                              'Old Password',
                              _obscureOldPassword,
                              () => setState(
                                () =>
                                    _obscureOldPassword = !_obscureOldPassword,
                              ),
                            ),
                          _buildPasswordField(
                            _newPasswordController,
                            'New Password',
                            _obscureNewPassword,
                            () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            ),
                          ),
                          _buildPasswordField(
                            _confirmPasswordController,
                            'Confirm New Password',
                            _obscureConfirmPassword,
                            () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CupertinoButton.filled(
                          onPressed: _isLoading ? null : _setOrChangePassword,
                          child: _isLoading
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : Text(
                                  _isPasswordSet
                                      ? 'Change Password'
                                      : 'Set Password',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
