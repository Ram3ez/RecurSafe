import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:recursafe/items/password_item.dart";

class PasswordProvider extends ChangeNotifier {
  late Box<PasswordItem> _passwordsBox;
  List<PasswordItem> _passwords = [];

  List<PasswordItem> get passwords => _passwords;

  PasswordProvider() {
    _passwordsBox = Hive.box<PasswordItem>('passwordsBox');
    _loadPasswords();
  }

  void addPassword({
    required String displayName,
    required String websiteName,
    required String userName,
    required DateTime addedOn,
  }) async {
    final newPassword = PasswordItem(
      displayName: displayName,
      websiteName: websiteName,
      userName: userName,
      addedOn: addedOn,
    );
    await _passwordsBox.add(newPassword);
    _loadPasswords();
  }

  void _loadPasswords() {
    _passwords = _passwordsBox.values.toList().cast<PasswordItem>();
    _passwords.sort((a, b) => b.addedOn.compareTo(a.addedOn)); // Newest first
    notifyListeners();
  }

  Future<void> deletePassword(PasswordItem password) async {
    await password
        .delete(); // Assumes PasswordItem extends HiveObject and is managed by the box
    _loadPasswords(); // Reload and notify listeners
  }

  // TODO: Add method for updating passwords in the box
}
