import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:recursafe/items/document_item.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class DocumentProvider extends ChangeNotifier {
  List<DocumentItem> _documents = [];
  final String _boxName = 'documentsBox';
  bool _isLoading = false;

  DocumentProvider() {
    loadDocuments();
  }

  List<DocumentItem> get documents => _documents;
  bool get isLoading => _isLoading;

  Future<void> _setLoading(bool loading) async {
    _isLoading = loading;
    // Use a microtask to ensure listeners are notified after the current event loop cycle
    Future.microtask(() => notifyListeners());
  }

  Future<void> loadDocuments() async {
    await _setLoading(true);
    final box = await Hive.openBox<DocumentItem>(_boxName);
    _documents = box.values.toList();
    // Sort documents by addedOn date, newest first
    _documents.sort((a, b) => b.addedOn.compareTo(a.addedOn));
    await _setLoading(false);
  }

  Future<String> getFullPathForDocumentFile(DocumentItem document) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return p.join(appDocDir.path, kDocumentsSubDir, document.fileName);
  }

  Future<void> addDocument({
    required String originalFileName, // The name from the file picker
    required String
    copiedFilePath, // The full path where the file was copied in kDocumentsSubDir
    required int size,
    required DateTime addedOn,
    bool isLocked = false,
  }) async {
    await _setLoading(true);
    final box = Hive.box<DocumentItem>(_boxName);
    final String actualFileName = p.basename(
      copiedFilePath,
    ); // e.g., "mydoc.pdf"
    final String id = const Uuid().v4(); // Generate a unique ID

    final newDocument = DocumentItem(
      // id: id, // If your DocumentItem has an ID field managed by HiveObject, it's often implicit
      name: originalFileName, // User-facing name
      fileName: actualFileName, // File name for storage
      size: size,
      addedOn: addedOn,
      isLocked: isLocked,
    );

    // In a real app, you might encrypt the file at `copiedFilePath` here if it's not already
    // The Hive box itself is encrypted, but the file on disk might need separate encryption.

    await box.put(id, newDocument); // Use a unique key for Hive, like an ID
    _documents.add(newDocument);
    _documents.sort((a, b) => b.addedOn.compareTo(a.addedOn)); // Re-sort
    await _setLoading(false);
  }

  Future<void> deleteDocument(DocumentItem document) async {
    await _setLoading(true);
    final box = Hive.box<DocumentItem>(_boxName);

    try {
      final filePath = await getFullPathForDocumentFile(document);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting file from filesystem: $e");
      }
      // Decide if you want to proceed with DB deletion even if file deletion fails
    }

    // Find the key for the document to delete it from Hive
    // This assumes DocumentItem.key is available (HiveObject provides it)
    // Or, if you used a custom ID as key when putting:
    String? keyToDelete;
    for (var entry in box.toMap().entries) {
      if (entry.value.fileName == document.fileName &&
          entry.value.name == document.name &&
          entry.value.addedOn == document.addedOn) {
        // Match more robustly
        keyToDelete = entry.key as String?;
        break;
      }
    }

    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    } else if (document.isInBox) {
      // Fallback if DocumentItem itself knows its key
      await document.delete();
    }

    _documents.removeWhere(
      (doc) =>
          doc.fileName == document.fileName &&
          doc.name == document.name &&
          doc.addedOn == document.addedOn,
    );
    await _setLoading(false);
  }

  Future<void> toggleLockStatus(DocumentItem document) async {
    await _setLoading(true);
    document.isLocked = !document.isLocked;
    // DocumentItem extends HiveObject, so save() should persist changes
    // Ensure the document instance is the one from the Hive box or has its key set.
    if (document.isInBox) {
      await document.save();
    } else {
      // If it's not in the box (e.g., a copy), you might need to find and update
      // This scenario should ideally be avoided by working with Hive-managed instances.
      final box = Hive.box<DocumentItem>(_boxName);
      // Find the key and update (more complex, better to ensure `document` is from Hive)
      String? keyToUpdate;
      for (var entry in box.toMap().entries) {
        if (entry.value.fileName == document.fileName &&
            entry.value.name == document.name &&
            entry.value.addedOn == document.addedOn) {
          keyToUpdate = entry.key as String?;
          break;
        }
      }
      if (keyToUpdate != null) {
        await box.put(keyToUpdate, document);
      }
    }
    await _setLoading(false);
  }

  /// Gets the accessible path for a document.
  /// This might involve decryption to a temporary file in a real scenario.
  /// For now, it assumes the file in kDocumentsSubDir is directly usable.
  Future<String> getAccessibleDocumentPath(DocumentItem document) async {
    final String currentFullPath = await getFullPathForDocumentFile(document);
    final File file = File(currentFullPath);

    if (!await file.exists()) {
      throw Exception(
        "Document file '${document.fileName}' not found at $currentFullPath.",
      );
    }
    // If files in kDocumentsSubDir need decryption to a temp location before opening:
    // 1. Decrypt `currentFullPath` to a temporary file.
    // 2. Return the path to the temporary decrypted file.
    // For now, returning the direct path:
    return currentFullPath;
  }

  // Method to update the lastOpened field for a document item
  Future<void> updateLastOpened(DocumentItem item) async {
    if (!item.isInBox) {
      // This can happen if the item instance is not the one managed by Hive.
      // It's safer to fetch the item by its key if this occurs, but for now, we'll log and return.
      print(
        "DocumentProvider: Attempted to update lastOpened for an item not in Hive box: ${item.name}",
      );
      return;
    }
    final now = DateTime.now();
    // Create a new instance with the updated lastOpened date
    // This is necessary because DocumentItem fields are not all final, but isLocked can change.
    // For consistency with PasswordProvider and to ensure Hive updates correctly with a new object.
    final updatedItem = DocumentItem(
      name: item.name,
      fileName: item.fileName,
      size: item.size,
      addedOn: item.addedOn,
      isLocked: item.isLocked,
      lastOpened: now, // Set lastOpened to current time
    );

    final box = Hive.box<DocumentItem>(_boxName);
    // 'item.key' will be the key used when it was put into the box (the UUID string 'id')
    await box.put(item.key, updatedItem);

    // Update the local list more efficiently
    final index = _documents.indexWhere(
      (doc) => doc.key == item.key,
    ); // Match by key

    if (index != -1) {
      _documents[index] = updatedItem;
      // The primary sort order in _documents is by addedOn.
      // HomePage already re-sorts by lastOpened.
      notifyListeners(); // Notify after local list update
    } else {
      // Fallback: if item wasn't found in local cache (should be rare if 'item' is from the list),
      // reload all to ensure consistency.
      await loadDocuments();
    }
  }

  Future<void> clearAllDocuments() async {
    await _setLoading(true);
    final box = Hive.box<DocumentItem>(_boxName);

    // Delete files from filesystem
    for (final document in _documents) {
      try {
        final filePath = await getFullPathForDocumentFile(document);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error deleting file ${document.fileName} from filesystem: $e");
        }
        // Continue even if a file deletion fails, to clear the DB
      }
    }
    await box.clear(); // Clear all entries from the Hive box
    _documents.clear(); // Clear the local list
    await _setLoading(false); // This will notify listeners
  }
}
