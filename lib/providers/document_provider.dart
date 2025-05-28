import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "dart:io"; // Import for File operations
import "package:recursafe/items/document_item.dart";

class DocumentProvider extends ChangeNotifier {
  late Box<DocumentItem> _documentsBox;
  List<DocumentItem> _documents = [];

  List<DocumentItem> get documents => _documents;

  DocumentProvider() {
    _documentsBox = Hive.box<DocumentItem>('documentsBox');
    _loadDocuments();
  }

  void addDocument({
    required String name,
    required String path,
    required int size, // Accept size as int
    required DateTime addedOn,
  }) async {
    final newDocument = DocumentItem(
      name: name,
      path: path,
      size: size,
      addedOn: addedOn,
    );
    await _documentsBox.add(
      newDocument,
    ); // Hive assigns an auto-incrementing key
    _loadDocuments(); // Reload from box to keep list in sync
  }

  void _loadDocuments() {
    _documents = _documentsBox.values.toList().cast<DocumentItem>();
    // Optionally sort them here if needed, e.g., by addedOn date
    _documents.sort((a, b) => b.addedOn.compareTo(a.addedOn)); // Newest first
    notifyListeners();
  }

  Future<void> deleteDocument(DocumentItem document) async {
    // Attempt to delete the physical file first
    try {
      final filePath = document.path;
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print("Successfully deleted file from local storage: $filePath");
      } else {
        print("File not found at $filePath, cannot delete from local storage.");
      }
    } catch (e) {
      print("Error deleting file from local storage $document.path: $e");
      // Depending on your error handling strategy, you might choose not to proceed
      // with deleting the Hive record if the file deletion fails.
      // For this implementation, we'll proceed to remove the record from the app.
    }
    await document.delete(); // Delete the record from Hive
    _loadDocuments(); // Reload and notify listeners to update the UI
  }

  void updateDocumentLockStatus(DocumentItem document, bool isLocked) {
    // Find the document by its key (HiveObject has a key property)
    final docToUpdate = _documentsBox.get(document.key);
    if (docToUpdate != null) {
      docToUpdate.isLocked = isLocked;
      docToUpdate.save(); // Save the changes to Hive
      // No need to call _loadDocuments() if you're updating the instance in the _documents list directly
      // However, to ensure UI consistency if other parts rely on a fresh list, _loadDocuments() is safer.
      _loadDocuments(); // Reload and notify listeners
    }
  }
}
