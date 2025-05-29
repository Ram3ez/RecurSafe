import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:recursafe/items/password_item.dart';
import 'package:recursafe/providers/password_provider.dart';
import 'package:recursafe/utils/dialog_utils.dart';

class AddEditPasswordPage extends StatefulWidget {
  final PasswordItem? passwordItem; // For editing existing item

  const AddEditPasswordPage({super.key, this.passwordItem});

  bool get isEditing => passwordItem != null;

  @override
  State<AddEditPasswordPage> createState() => _AddEditPasswordPageState();
}

class _AddEditPasswordPageState extends State<AddEditPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _websiteNameController;
  late TextEditingController _userNameController;
  late TextEditingController _passwordController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.passwordItem?.displayName ?? '',
    );
    _websiteNameController = TextEditingController(
      text: widget.passwordItem?.websiteName ?? '',
    );
    _userNameController = TextEditingController(
      text: widget.passwordItem?.userName ?? '',
    );
    _passwordController =
        TextEditingController(); // Password is not pre-filled for editing for security
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _websiteNameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (_formKey.currentState!.validate()) {
      final passwordProvider = context.read<PasswordProvider>();
      try {
        if (widget.isEditing) {
          await passwordProvider.updatePassword(
            widget.passwordItem!,
            displayName: _displayNameController.text,
            websiteName: _websiteNameController.text,
            userName: _userNameController.text,
            plainPassword: _passwordController
                .text, // Always pass, provider handles if empty
          );
        } else {
          await passwordProvider.addPassword(
            displayName: _displayNameController.text,
            websiteName: _websiteNameController.text,
            userName: _userNameController.text,
            plainPassword: _passwordController.text,
            addedOn: DateTime.now(),
          );
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          DialogUtils.showInfoDialog(
            context,
            "Error",
            "Failed to save password: $e",
          );
        }
      }
    }
  }

  Widget _buildTextFieldRow({
    required TextEditingController controller,
    required String placeholder,
    required String prefixLabel, // Changed from IconData to String
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(
          right: 8.0,
        ), // Keep padding for the label
        child: Text(
          prefixLabel,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
      child: FormField<String>(
        initialValue: controller.text,
        validator:
            validator ??
            (value) {
              // Use controller.text for validation as FormField's value might not update immediately with controller
              final text = controller.text;
              if (text.isEmpty) {
                return '$placeholder is required';
              }
              // Apply password length validation only if it's a password field
              if (isPassword) {
                if (!widget.isEditing && text.length < 6) {
                  // Adding new password
                  return 'Password must be at least 6 characters';
                }
                if (widget.isEditing && text.isNotEmpty && text.length < 6) {
                  // Editing and new password entered
                  return 'New password must be at least 6 characters';
                }
              }
              return null;
            },
        builder: (FormFieldState<String> field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoTextField(
                controller: controller,
                placeholder: placeholder,
                keyboardType: keyboardType,
                obscureText: isPassword ? _obscurePassword : false,
                textCapitalization: textCapitalization,
                onChanged: (text) =>
                    // Ensure FormField's value is updated for validation,
                    // though direct controller access in validator is also used.
                    field.didChange(text), // Update FormField state
                suffix: isPassword
                    ? Padding(
                        padding: const EdgeInsets.only(
                          right: 8.0,
                        ), // Added right padding for the eye icon
                        child: CupertinoButton(
                          padding: const EdgeInsets.only(left: 8.0),
                          minSize: 0,
                          child: Icon(
                            _obscurePassword
                                ? CupertinoIcons.eye_slash_fill
                                : CupertinoIcons.eye_fill,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 0.0,
                ), // Consistent padding
                decoration: null, // Remove default border to blend with FormRow
              ),
              if (field.hasError)
                Padding(
                  // The CupertinoFormRow already provides some spacing,
                  // so this padding is primarily for the top margin of the error text.
                  // The error text will align with the text field due to the Column structure.
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed.resolveFrom(
                        context,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.isEditing ? 'Edit Password' : 'Add New Password'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(widget.isEditing ? 'Save' : 'Add'),
          onPressed: _savePassword,
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(
              top:
                  16.0, // Increased top padding to push the content down slightly more
            ), // Added top padding to push the content down
            child: ListView(
              children: [
                CupertinoFormSection.insetGrouped(
                  header: const Text('Password Details'),
                  children: [
                    _buildTextFieldRow(
                      controller: _displayNameController,
                      placeholder: 'Display Name (e.g., Google Account)',
                      prefixLabel: 'Name',
                      textCapitalization: TextCapitalization.words,
                    ),
                    _buildTextFieldRow(
                      controller: _websiteNameController,
                      placeholder: 'Website (e.g., google.com)',
                      prefixLabel: 'Website',
                      keyboardType: TextInputType.url,
                    ),
                    _buildTextFieldRow(
                      controller: _userNameController,
                      placeholder: 'Username or Email',
                      prefixLabel: 'Username',
                    ),
                    _buildTextFieldRow(
                      controller: _passwordController,
                      placeholder: 'Password',
                      prefixLabel: 'Password',
                      isPassword: true,
                      validator: (value) {
                        // Validator for the FormField
                        // Password optional when editing, required when adding
                        // Note: 'value' here is from FormField, but we use controller.text in the builder for immediate validation
                        final text = _passwordController.text;
                        if (!widget.isEditing && text.isEmpty) {
                          return 'Password is required';
                        }
                        if (text.isNotEmpty && text.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
