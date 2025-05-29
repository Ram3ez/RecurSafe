import "package:flutter/cupertino.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:recursafe/items/password_item.dart";
import 'package:recursafe/services/password_encryption_service.dart';

class PasswordProvider extends ChangeNotifier {
  final Box<PasswordItem> _passwordsBox = Hive.box<PasswordItem>(
    'passwordsBox',
  );
  final PasswordEncryptionService _encryptionService =
      PasswordEncryptionService();
  List<PasswordItem> _passwords = []; // Local cache

  List<PasswordItem> get passwords => _passwords;

  PasswordProvider() {
    _loadPasswords();
    // Listen to box changes to keep the local list in sync
    _passwordsBox.watch().listen((event) {
      _loadPasswords();
    });
  }

  void _loadPasswords() {
    _passwords = _passwordsBox.values.toList();
    _passwords.sort((a, b) => b.addedOn.compareTo(a.addedOn)); // Newest first
    notifyListeners();
  }

  Future<void> addPassword({
    required String displayName,
    required String websiteName,
    required String userName,
    required String plainPassword,
    required DateTime addedOn,
  }) async {
    final encryptionResult = await _encryptionService.encryptPassword(
      plainPassword,
    );

    final newPassword = PasswordItem(
      displayName: displayName,
      websiteName: websiteName,
      userName: userName,
      encryptedPassword: encryptionResult['encryptedText']!,
      ivBase64: encryptionResult['ivBase64']!,
      addedOn: addedOn,
    );
    await _passwordsBox.add(newPassword);
    // _loadPasswords(); // Not strictly needed if listening to box changes, but can be kept for immediate UI update
  }

  Future<void> deletePassword(PasswordItem password) async {
    await password.delete();
    // _loadPasswords(); // Not strictly needed if listening to box changes
  }

  Future<void> updatePassword(
    PasswordItem oldPassword, {
    String? displayName,
    String? websiteName,
    String? userName,
    String? plainPassword, // New plain text password, if being changed
  }) async {
    String newEncryptedPassword = oldPassword.encryptedPassword;
    String? newIvBase64 = oldPassword.ivBase64;

    if (plainPassword != null && plainPassword.isNotEmpty) {
      final encryptionResult = await _encryptionService.encryptPassword(
        plainPassword,
      );
      newEncryptedPassword = encryptionResult['encryptedText']!;
      newIvBase64 = encryptionResult['ivBase64']!;
    }

    final updatedPasswordItem = PasswordItem(
      displayName: displayName ?? oldPassword.displayName,
      websiteName: websiteName ?? oldPassword.websiteName,
      userName: userName ?? oldPassword.userName,
      encryptedPassword: newEncryptedPassword,
      ivBase64: newIvBase64,
      addedOn: oldPassword
          .addedOn, // Keep original addedOn date unless explicitly changed
    );

    // Use the key of the oldPassword to update it in the box
    await _passwordsBox.put(oldPassword.key, updatedPasswordItem);

    // The watch().listen() in the constructor should handle reloading and notifying.
    // If immediate update of the local _passwords list is desired before the watch event,
    // you could call _loadPasswords() here, but it might be redundant.
  }

  Future<String> getDecryptedPassword(PasswordItem item) async {
    if (item.ivBase64 == null) {
      // This should ideally not happen if IV is always saved during encryption
      throw Exception("IV not found for password item. Cannot decrypt.");
    }
    return _encryptionService.decryptPassword(
      item.encryptedPassword,
      item.ivBase64!,
    );
  }
}
