import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
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
    await document
        .delete(); // Assumes DocumentItem extends HiveObject and is managed by the box
    _loadDocuments(); // Reload and notify listeners
  }

  // TODO: Add method for updating documents in the box
}
