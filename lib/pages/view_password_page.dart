import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:recursafe/items/password_item.dart';
import 'package:recursafe/providers/password_provider.dart';
import 'package:recursafe/pages/add_edit_password_page.dart'; // For navigation to edit page
import 'package:recursafe/services/auth_service.dart';
import 'package:recursafe/utils/dialog_utils.dart';

class ViewPasswordPage extends StatefulWidget {
  final PasswordItem passwordItem;

  const ViewPasswordPage({super.key, required this.passwordItem});

  @override
  State<ViewPasswordPage> createState() => _ViewPasswordPageState();
}

class _ViewPasswordPageState extends State<ViewPasswordPage> {
  // State for viewing
  bool _isPasswordVisible = false;
  String _decryptedPassword = "";
  bool _isProcessing = false;
  Timer? _clipboardMessageTimer;
  OverlayEntry? _overlayEntry; // For the snackbar-like message

  // State for editing
  bool _isEditing = false;
  late TextEditingController _websiteController;
  late TextEditingController _userNameController;
  late TextEditingController
  _passwordController; // For new password input during edit
  bool _obscurePasswordInEdit =
      true; // For the password text field when editing

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _clipboardMessageTimer?.cancel();
    _overlayEntry?.remove(); // Ensure overlay is removed on dispose
    _websiteController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _websiteController = TextEditingController(
      text: widget.passwordItem.websiteName,
    );
    _userNameController = TextEditingController(
      text: widget.passwordItem.userName,
    );
    _passwordController = TextEditingController(); // Password not pre-filled
  }

  void _showClipboardStatusMessage(String message, {bool isError = false}) {
    _clipboardMessageTimer?.cancel();
    _overlayEntry?.remove(); // Remove previous overlay if any
    _overlayEntry = null;

    if (!mounted) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            30.0, // Position above keyboard + padding
        left: 0,
        right: 0,
        child: IgnorePointer(
          // So it doesn't intercept taps
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isError
                    ? CupertinoColors.destructiveRed
                          .resolveFrom(context)
                          .withOpacity(0.9)
                    : CupertinoColors.darkBackgroundGray.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  decoration:
                      TextDecoration.none, // Ensure no default text decoration
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);

    _clipboardMessageTimer = Timer(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Future<void> _handlePasswordAction({
    bool forRevealToggle = false,
    bool forCopy = false,
  }) async {
    if (_isProcessing) return;

    // If password is visible and we just want to copy it (not in edit mode)
    if (_isPasswordVisible && forCopy && !forRevealToggle) {
      await Clipboard.setData(ClipboardData(text: _decryptedPassword));
      _showClipboardStatusMessage("Password Copied!");
      return;
    }
    setState(() {
      _isProcessing = true;
    });

    await _authService.authenticateAndExecute(
      context: context,
      localizedReason: forRevealToggle
          ? (_isPasswordVisible
                ? 'To hide password for "${widget.passwordItem.displayName}", please authenticate.'
                : 'To view password for "${widget.passwordItem.displayName}", please authenticate.')
          : 'To copy password for "${widget.passwordItem.displayName}", please authenticate.',
      itemName: widget.passwordItem.displayName,
      onAuthenticated: () async {
        try {
          if (!_isPasswordVisible || _decryptedPassword.isEmpty) {
            final passwordProvider = context.read<PasswordProvider>();
            _decryptedPassword = await passwordProvider.getDecryptedPassword(
              widget.passwordItem,
            );
          }

          if (forCopy) {
            await Clipboard.setData(ClipboardData(text: _decryptedPassword));
            _showClipboardStatusMessage("Password Copied!");
          }

          if (mounted) {
            if (forRevealToggle) {
              setState(() => _isPasswordVisible = !_isPasswordVisible);
            } else if (forCopy && !_isPasswordVisible) {
              // If copied and was not visible, make it visible
              setState(() => _isPasswordVisible = true);
            }
          }
        } catch (e) {
          if (mounted) {
            _showClipboardStatusMessage("Decryption Error!", isError: true);
            print("Decryption Error: $e");
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      },
      onNotAuthenticated: () async {
        if (mounted) setState(() => _isProcessing = false);
        _showClipboardStatusMessage("Authentication Failed.", isError: true);
      },
    );
  }

  Future<void> _enterEditMode() async {
    if (_isProcessing) return; // Prevent action if another is in progress

    setState(() {
      _isProcessing = true; // Indicate processing for the edit action
    });

    // Reset controllers to current item state before editing
    _websiteController.text = widget.passwordItem.websiteName;
    _userNameController.text = widget.passwordItem.userName;
    _passwordController.clear(); // Always clear password field for editing
    await _authService.authenticateAndExecute(
      context: context,
      localizedReason:
          'To edit password for "${widget.passwordItem.displayName}", please authenticate.',
      itemName: widget.passwordItem.displayName,
      onAuthenticated: () async {
        if (mounted) {
          setState(() {
            _isEditing = true;
            _isProcessing = false;
            // If password was visible in view mode, hide it to avoid confusion with edit field
            _isPasswordVisible = false;
          });
        }
      },
      onNotAuthenticated: () async {
        if (mounted) setState(() => _isProcessing = false);
        _showClipboardStatusMessage(
          "Authentication Failed.",
          isError: true,
        );
      },
    );
  }

  void _cancelEditMode() {
    setState(() {
      _isEditing = false;
      // Reset controllers to original item values
      _websiteController.text = widget.passwordItem.websiteName;
      _userNameController.text = widget.passwordItem.userName;
      _passwordController.clear();
      _obscurePasswordInEdit = true;
    });
  }

  Future<void> _saveChanges() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final passwordProvider = context.read<PasswordProvider>();
    try {
      // Basic validation (can be expanded)
      if (_websiteController.text.isEmpty || _userNameController.text.isEmpty) {
        _showClipboardStatusMessage(
          "Website and Username cannot be empty.",
          isError: true,
        );
        setState(() => _isProcessing = false);
        return;
      }
      // Password validation (optional if empty, length if provided)
      if (_passwordController.text.isNotEmpty &&
          _passwordController.text.length < 6) {
        _showClipboardStatusMessage(
          "New password must be at least 6 characters.",
          isError: true,
        );
        setState(() => _isProcessing = false);
        return;
      }

      await passwordProvider.updatePassword(
        widget.passwordItem, // The original item to find and update
        displayName:
            widget.passwordItem.displayName, // Display name not edited here
        websiteName: _websiteController.text,
        userName: _userNameController.text,
        plainPassword: _passwordController
            .text, // Pass new password, provider handles if empty
      );
      _showClipboardStatusMessage("Changes Saved!");
      setState(() => _isEditing = false);
    } catch (e) {
      _showClipboardStatusMessage("Failed to save: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isPassword = false,
    bool canCopy = false,
  }) {
    if (_isEditing) {
      TextEditingController? currentController;
      TextInputType keyboardType = TextInputType.text;
      bool isPasswordFieldInEdit = false;

      if (label == 'Website') {
        currentController = _websiteController;
        keyboardType = TextInputType.url;
      } else if (label == 'Username') {
        currentController = _userNameController;
      } else if (label == 'Password') {
        currentController = _passwordController;
        isPasswordFieldInEdit = true;
      }

      if (currentController != null) {
        return CupertinoFormRow(
          // Using CupertinoFormRow for standard editing UI
          prefix: Padding(
            padding: const EdgeInsets.only(
              right: 8.0,
            ), // Add right padding to the label
            child: Text(
              label,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          child: CupertinoTextField(
            controller: currentController,
            placeholder: isPasswordFieldInEdit
                ? "New Password (optional)"
                : "Enter $label",
            keyboardType:
                keyboardType, // Standard iOS padding for text fields in a form row
            obscureText: isPasswordFieldInEdit
                ? _obscurePasswordInEdit
                : false, // Standard iOS padding for text fields in a form row
            textCapitalization:
                label ==
                    'Website' // Standard iOS padding for text fields in a form row
                ? TextCapitalization
                      .none // Standard iOS padding for text fields in a form row
                : TextCapitalization
                      .sentences, // Standard iOS padding for text fields in a form row
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 0.0,
            ), // Standard iOS padding for text fields in a form row
            decoration: null, // Remove default border to blend with FormRow
            suffix: isPasswordFieldInEdit
                ? CupertinoButton(
                    padding: const EdgeInsets.only(left: 8.0),
                    minSize: 0,
                    child: Icon(
                      _obscurePasswordInEdit
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePasswordInEdit = !_obscurePasswordInEdit;
                      });
                    },
                  )
                : null,
          ),
        );
      }
      return const SizedBox.shrink(); // Should not happen if labels match
    } else {
      // View Mode
      Widget content = Text(
        isPassword
            ? (_isPasswordVisible ? _decryptedPassword : '••••••••')
            : value,
        style: const TextStyle(fontSize: 17),
        maxLines: isPassword ? 1 : null,
        overflow: isPassword ? TextOverflow.ellipsis : null,
      );

      return CupertinoListTile.notched(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: content,
        ),
        trailing: isPassword
            ? CupertinoButton(
                padding: const EdgeInsets.only(left: 16.0, right: 4.0),
                minSize: 0,
                onPressed: _isProcessing || _isEditing
                    ? null
                    : () => _handlePasswordAction(forRevealToggle: true),
                child: _isProcessing && !_isPasswordVisible && !_isEditing
                    ? const CupertinoActivityIndicator(radius: 11)
                    : Icon(
                        _isPasswordVisible
                            ? CupertinoIcons.eye_slash_fill
                            : CupertinoIcons.eye_fill,
                        size: 24,
                      ),
              )
            : (canCopy
                  ? const Icon(
                      CupertinoIcons.doc_on_clipboard,
                      color: CupertinoColors.systemGrey,
                      size: 22,
                    )
                  : null),
        onTap: canCopy && !_isEditing
            ? () async {
                if (isPassword) {
                  await _handlePasswordAction(forCopy: true);
                } else {
                  await Clipboard.setData(ClipboardData(text: value));
                  _showClipboardStatusMessage("$label Copied!");
                }
              }
            : null,
        additionalInfo:
            isPassword && _isProcessing && _isPasswordVisible && !_isEditing
            ? const CupertinoActivityIndicator(radius: 10)
            : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.passwordItem.displayName),
        leading: _isEditing
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text("Cancel"),
                onPressed: _isProcessing ? null : _cancelEditMode,
              )
            : null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isProcessing
              ? null
              : (_isEditing ? _saveChanges : _enterEditMode),
          child: Text(_isEditing ? "Save" : "Edit"),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ), // Match section background
        border: null, // Remove border for a cleaner look with grouped sections
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ), // Background for the whole page
      child: SafeArea(
        child: ListView(
          children: [
            // const SizedBox(height: 20), // Removed fixed SizedBox, relying on section margins
            CupertinoFormSection.insetGrouped(
              header: Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  bottom: 6.0,
                  top: 20.0,
                ), // iOS like header padding
                child: Text(
                  'Password Details',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              // Removed footer that previously showed clipboard status message
              children: [
                _buildDetailRow(
                  label: 'Website',
                  value: widget.passwordItem.websiteName,
                  canCopy: true,
                ),
                _buildDetailRow(
                  label: 'Username',
                  value: widget.passwordItem.userName,
                  canCopy: true,
                ),
                _buildDetailRow(
                  label: 'Password',
                  value: "",
                  isPassword: true,
                  canCopy: true,
                ),
              ],
            ),
            // Removed the dedicated "Copy Password" button
            // Padding(
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: 20.0,
            //     vertical: 10.0,
            //   ),
            //   child: CupertinoButton.filled(
            //     onPressed: _isProcessing
            //         ? null
            //         : () => _handlePasswordAction(forCopy: true),
            //     child:
            //         _isProcessing &&
            //             _clipboardStatusMessage
            //                 .isEmpty // Show loader only when processing copy
            //         ? const CupertinoActivityIndicator(
            //             color: CupertinoColors.white,
            //           )
            //         : const Text('Copy Password'),
            //   ),
            // ),
            // if (_clipboardStatusMessage.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 20.0,
            //       vertical: 5.0,
            //     ),
            //     child: Center(
            //       child: Text(
            //         _clipboardStatusMessage,
            //         style: TextStyle(
            //           color:
            //               _clipboardStatusMessage.contains("Error") ||
            //                   _clipboardStatusMessage.contains("Failed")
            //               ? CupertinoColors.destructiveRed.resolveFrom(context)
            //               : CupertinoColors.systemGreen.resolveFrom(context),
            //         ),
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
