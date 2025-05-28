import "package:flutter/cupertino.dart";
import "package:provider/provider.dart";
import "package:recursafe/components/base_page.dart";
import "package:recursafe/components/custom_item.dart";
import "package:recursafe/providers/password_provider.dart";
import "package:recursafe/items/password_item.dart";
//import "package:flutter/foundation.dart"; // Import for kReleaseMode if needed later

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  String _searchQuery = '';
  bool _isEditing = false;

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
        context.read<PasswordProvider>().addPassword(
          displayName: "test",
          websiteName: "test2",
          userName: "wow",
          addedOn: DateTime.now(),
        );
      },
      body: SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: filteredPasswords.length,
          (context, index) => CustomItem(
            isEditing: _isEditing,
            passwordItem: filteredPasswords[index],
            onDelete: () {
              // Optional: Show a confirmation dialog
              final passwordToDelete = filteredPasswords[index];
              context.read<PasswordProvider>().deletePassword(passwordToDelete);
            },
          ),
        ),
      ),
    );
  }
}
