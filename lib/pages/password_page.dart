import "package:flutter/cupertino.dart";
import "package:provider/provider.dart";
import "package:recursafe/components/base_page.dart";
import "package:recursafe/components/custom_item.dart";
import "package:recursafe/providers/password_provider.dart";
import "package:recursafe/items/password_item.dart";
import "package:recursafe/pages/add_edit_password_page.dart";
import "package:recursafe/pages/view_password_page.dart"; // Import the new page
import "package:recursafe/services/auth_service.dart"; // Import AuthService
//import "package:flutter/foundation.dart"; // Import for kReleaseMode if needed later

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  String _searchQuery = '';
  bool _isEditing = false;
  final AuthService _authService = AuthService(); // Instantiate AuthService

  void _handleSearchChanged(String query) {
    // Optional: Add a debounce here for performance on large lists
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // _searchQuery = ''; // Optionally clear search
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwordProvider = context.watch<PasswordProvider>();
    final allPasswords = passwordProvider.passwords;

    final filteredPasswords = _searchQuery.isEmpty
        ? allPasswords
        : allPasswords
              .where(
                (password) =>
                    password.displayName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    password.websiteName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return BasePage(
      title: "Passwords",
      searchPlaceholder: "Search Password",
      isEditing: _isEditing,
      onEdit: _toggleEditMode,
      onSearchChanged: _handleSearchChanged,
      onAdd: () {
        // For adding a new password
        // Get the existing PasswordProvider instance from the current context
        final passwordProvider = context.read<PasswordProvider>();
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (newContext) => ChangeNotifierProvider.value(
              value: passwordProvider, // Provide the existing instance
              child: const AddEditPasswordPage(),
            ),
          ),
        );
      },
      body: SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: filteredPasswords.length,
          (context, index) => CustomItem(
            isEditing: _isEditing,
            passwordItem: filteredPasswords[index],
            onDelete: () async {
              // Make onDelete async
              final passwordToDelete = filteredPasswords[index];
              final passwordProvider = context.read<PasswordProvider>();

              // Always authenticate for password deletion
              await _authService.authenticateAndExecute(
                // Add await
                context: context,
                localizedReason:
                    'To delete password "${passwordToDelete.displayName}", please authenticate.',
                itemName: passwordToDelete.displayName,
                onAuthenticated: () async {
                  await passwordProvider.deletePassword(passwordToDelete);
                },
                onNotAuthenticated: () async {
                  // Optional: Handle if authentication fails
                  print(
                    'Authentication failed for deleting password: ${passwordToDelete.displayName}',
                  );
                },
              );
            },
            onTap: () {
              if (!_isEditing) {
                final passwordProvider = context.read<PasswordProvider>();
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (newContext) => ChangeNotifierProvider.value(
                      value: passwordProvider,
                      child: ViewPasswordPage(
                        passwordProvider: context.read<PasswordProvider>(),
                        passwordItem: filteredPasswords[index],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
