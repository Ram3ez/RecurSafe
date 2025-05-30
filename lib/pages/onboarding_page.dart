import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:recursafe/utils/crypto_utils.dart'; // Import the utility

class OnboardingPage extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingPage({super.key, required this.onOnboardingComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _secureStorage = const FlutterSecureStorage();

  Future<void> _setMasterPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      setState(() {
        _errorMessage = "Password cannot be empty.";
        _isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      // Basic password length validation
      setState(() {
        _errorMessage = "Password must be at least 6 characters long.";
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match.";
        _isLoading = false;
      });
      return;
    }

    try {
      final String hashedPassword = hashPassword(password);

      await _secureStorage.write(
        key: 'master_password_hash', // Use the same key as MasterPasswordPage
        value: hashedPassword,
      );
      await _secureStorage.write(key: 'onboarding_complete', value: 'true');

      print(
        "[DEBUG] OnboardingPage: Master password set and onboarding marked complete.",
      );
      widget.onOnboardingComplete();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to save password. Please try again.";
        _isLoading = false;
        print("[ERROR] OnboardingPage: Failed to set master password - $e");
      });
    }
    // If successful, navigation will occur, so no need to set _isLoading = false.
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Welcome to RecurSafe"), // Changed title
        automaticallyImplyLeading: false, // No back button during onboarding
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Changed from center to start
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(
                  height:
                      40, // Increased from 20 to 40 (or any value you prefer)
                ),
                // Add the App Logo here
                Image.asset(
                  'assets/icon.png', // Make sure this path is correct
                  height: 100, // Adjust size as needed
                  width: 100, // Adjust size as needed
                ), // Added some top padding if needed when scrolling
                const Text(
                  "Welcome to RecurSafe!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label, // Adapts to light/dark mode
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "RecurSafe helps you securely store and manage your important documents and passwords. To get started and protect your sensitive information, please set a master password.",
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors
                        .systemGrey, // Changed color for better readability
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: "Enter Master Password",
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors
                        .tertiarySystemFill, // iOS-like text field background
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Icon(
                      CupertinoIcons.lock_fill,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  suffix: CupertinoButton(
                    padding: const EdgeInsets.only(right: 10.0),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Icon(
                      _obscurePassword
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
                      color: CupertinoColors.secondaryLabel,
                      size: 20,
                    ),
                  ),
                  onChanged: (_) => setState(() {
                    _errorMessage = null;
                  }), // Clear error on text change
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _confirmPasswordController,
                  placeholder: "Confirm Master Password",
                  obscureText: _obscureConfirmPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Icon(
                      CupertinoIcons.lock_fill,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  suffix: CupertinoButton(
                    padding: const EdgeInsets.only(right: 10.0),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    child: Icon(
                      _obscureConfirmPassword
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
                      color: CupertinoColors.secondaryLabel,
                      size: 20,
                    ),
                  ),
                  onChanged: (_) => setState(() {
                    _errorMessage = null;
                  }), // Clear error on text change
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 30),
                CupertinoButton.filled(
                  onPressed: _isLoading ? null : _setMasterPassword,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        ) // Ensure contrast
                      : const Text("Set Password and Continue"),
                ),
                const SizedBox(
                  height: 20,
                ), // Added some bottom padding if needed when scrolling
              ],
            ),
          ),
        ),
      ),
    );
  }
}
