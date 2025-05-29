import "package:flutter/cupertino.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:recursafe/items/password_item.dart";
import 'package:recursafe/services/password_encryption_service.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

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
    // lastOpened will be handled by PasswordItem constructor default
  }) async {
    final encryptionResult = await _encryptionService.encryptPassword(
      plainPassword,
    );
    final String newId = const Uuid().v4(); // Generate a unique ID

    final newPassword = PasswordItem(
      id: newId,
      displayName: displayName,
      websiteName: websiteName,
      userName: userName,
      encryptedPassword: encryptionResult['encryptedText']!,
      ivBase64: encryptionResult['ivBase64']!,
      addedOn: addedOn,
      // lastOpened is initialized by the constructor to addedOn
    );
    await _passwordsBox.put(newId, newPassword); // Use id as the key
    _loadPasswords(); // Explicitly reload to ensure UI updates immediately with sorted list
    // _loadPasswords(); // Not strictly needed if listening to box changes, but can be kept for immediate UI update
  }

  Future<void> deletePassword(PasswordItem password) async {
    await password.delete();
    // _loadPasswords(); // Not strictly needed if listening to box changes
    // The watch().listen() in the constructor should handle reloading.
  }

  Future<void> updatePassword(
    PasswordItem oldPassword, {
    String? displayName,
    String? websiteName,
    String? userName,
    String? plainPassword, // New plain text password, if being changed
    DateTime? lastOpened, // Allow updating lastOpened explicitly
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
      id: oldPassword.id, // Preserve the original ID
      displayName: displayName ?? oldPassword.displayName,
      websiteName: websiteName ?? oldPassword.websiteName,
      userName: userName ?? oldPassword.userName,
      encryptedPassword: newEncryptedPassword,
      ivBase64: newIvBase64,
      addedOn: oldPassword.addedOn, // Keep original addedOn date
      lastOpened:
          lastOpened ?? oldPassword.lastOpened, // Preserve or update lastOpened
    );

    // Use the key of the oldPassword to update it in the box
    // Since we're now using 'id' as the key, we should use oldPassword.id
    await _passwordsBox.put(oldPassword.id, updatedPasswordItem);
    _loadPasswords(); // Explicitly reload to ensure UI updates immediately

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

  // Method to update the lastOpened field for a password item
  Future<void> updateLastOpened(PasswordItem item) async {
    final now = DateTime.now();
    // Create a new instance with the updated lastOpened date
    // This is necessary because PasswordItem fields are final
    final updatedItem = PasswordItem(
      id: item.id,
      displayName: item.displayName,
      websiteName: item.websiteName,
      userName: item.userName,
      encryptedPassword: item.encryptedPassword,
      ivBase64: item.ivBase64,
      addedOn: item.addedOn,
      lastOpened: now, // Set lastOpened to current time
    );
    await _passwordsBox.put(item.id, updatedItem); // Use id as the key
    // _loadPasswords(); // The watch listener should pick this up.
    // Or, if you want to be absolutely sure the specific item in the local list is updated:
    final index = _passwords.indexWhere((p) => p.id == item.id);
    if (index != -1) {
      _passwords[index] = updatedItem;
      // The _passwords list is primarily sorted by addedOn.
      // HomePage will re-sort by lastOpened for its specific section.
      notifyListeners();
    } else {
      // Fallback: if item wasn't found in local cache, reload all.
      _loadPasswords(); // This will call notifyListeners
    }
  }

  Future<void> clearAllPasswords() async {
    // Passwords are only in Hive, no separate files to delete
    await _passwordsBox.clear(); // Clear all entries from the Hive box
    _passwords.clear(); // Clear the local list
    notifyListeners(); // Notify listeners directly
  }
}
