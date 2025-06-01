import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:recursafe/items/document_item.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:encrypt/encrypt.dart' as enc; // For encryption

class DocumentProvider extends ChangeNotifier {
  List<DocumentItem> _documents = [];
  final String _boxName = 'documentsBox';
  bool _isLoading = false;
  final Uint8List _encryptionKey;
  late final String _encryptedDocumentsDirPath;
  bool _isEncryptedDirInitialized = false;

  // Define a subdirectory for encrypted files, distinct from kDocumentsSubDir
  static const String _kEncryptedFilesSubDir = "recursafeDocs";

  DocumentProvider({required Uint8List encryptionKey})
    : _encryptionKey = encryptionKey {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize the directory path for encrypted files
    await _initEncryptedDocumentsDirectory();
    // Load documents from Hive
    await loadDocuments();
  }

  List<DocumentItem> get documents => _documents;
  bool get isLoading => _isLoading;

  Future<void> _setLoading(bool loading) async {
    _isLoading = loading;
    // Use a microtask to ensure listeners are notified after the current event loop cycle
    Future.microtask(() => notifyListeners());
  }

  enc.Encrypter _getEncrypter() {
    final key = enc.Key(_encryptionKey);
    // Using AES-CBC with PKCS7 padding. IV will be generated per file.
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
  }

  Future<void> _initEncryptedDocumentsDirectory() async {
    if (_isEncryptedDirInitialized) return;
    final appDir = await getApplicationDocumentsDirectory();
    _encryptedDocumentsDirPath = p.join(appDir.path, _kEncryptedFilesSubDir);
    final dir = Directory(_encryptedDocumentsDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      if (kDebugMode) {
        print(
          "Created encrypted documents directory: $_encryptedDocumentsDirPath",
        );
      }
    }
    _isEncryptedDirInitialized = true;
  }

  Future<void> loadDocuments() async {
    await _setLoading(true);
    final box = await Hive.openBox<DocumentItem>(_boxName);
    _documents = box.values.toList();
    // Sort documents by addedOn date, newest first
    _documents.sort((a, b) => b.addedOn.compareTo(a.addedOn));
    await _setLoading(false);
  }

  // This method is no longer accurate as document.fileName IS the full path.
  // Future<String> getFullPathForDocumentFile(DocumentItem document) async {
  //   final appDocDir = await getApplicationDocumentsDirectory();
  //   return p.join(appDocDir.path, kDocumentsSubDir, document.fileName);
  // }

  Future<String> _encryptAndSaveFile(
    String sourceFilePath,
    String originalFileNameForExt,
  ) async {
    if (!_isEncryptedDirInitialized) await _initEncryptedDocumentsDirectory();

    final encrypter = _getEncrypter();
    final iv = enc.IV.fromSecureRandom(16); // Generate a random IV

    final fileBytes = await File(sourceFilePath).readAsBytes();
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    // Prepend IV to the encrypted bytes: IV (16 bytes) + Ciphertext
    final bytesToWrite = Uint8List.fromList(iv.bytes + encrypted.bytes);

    // Use original file extension for the encrypted file for easier identification (optional)
    // Or use a generic ".enc" extension
    final extension = p.extension(originalFileNameForExt).isNotEmpty
        ? p.extension(originalFileNameForExt)
        : ".bin";
    final uniqueEncryptedFileName = '${const Uuid().v4()}$extension';
    final encryptedFilePath = p.join(
      _encryptedDocumentsDirPath,
      uniqueEncryptedFileName,
    );

    await File(encryptedFilePath).writeAsBytes(bytesToWrite);
    if (kDebugMode) {
      print("Encrypted and saved file to: $encryptedFilePath");
    }
    return uniqueEncryptedFileName; // Return only the base name
  }

  Future<void> addDocument({
    required String originalFileName, // The name from the file picker
    required String
    sourcePlatformPath, // The path from file picker (original unencrypted file)
    required int size,
    required DateTime addedOn,
    bool isLocked = false,
  }) async {
    await _setLoading(true);

    // Encrypt and save the file, get the path to the encrypted version
    final uniqueEncryptedFileName = await _encryptAndSaveFile(
      // This now returns the base name
      sourcePlatformPath,
      originalFileName,
    );
    final originalFileExt = p.extension(originalFileName);

    final box = Hive.box<DocumentItem>(_boxName);
    final String id = const Uuid().v4(); // Generate a unique ID

    final newDocument = DocumentItem(
      // id: id, // If your DocumentItem has an ID field managed by HiveObject, it's often implicit
      name: originalFileName, // User-facing name
      fileName:
          uniqueEncryptedFileName, // Store only the base name of the ENCRYPTED file
      size: size,
      addedOn: addedOn,
      isLocked: isLocked,
      originalFileExtension: originalFileExt.isNotEmpty
          ? originalFileExt
          : null,
    );

    await box.put(id, newDocument); // Use a unique key for Hive, like an ID
    _documents.add(newDocument);
    _documents.sort((a, b) => b.addedOn.compareTo(a.addedOn)); // Re-sort
    await _setLoading(false);
  }

  Future<void> deleteDocument(DocumentItem document) async {
    await _setLoading(true);
    final box = Hive.box<DocumentItem>(_boxName);

    try {
      // Reconstruct the full path to the encrypted file
      final fullPath = p.join(_encryptedDocumentsDirPath, document.fileName);
      final file = File(fullPath);
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
      if (entry.value.fileName ==
              document.fileName && // fileName is now base name
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
          doc.fileName == document.fileName && // fileName is now base name
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
      dynamic keyToUpdate; // Key can be int or String
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
  // This method now handles decryption to a temporary file.
  Future<String> getAccessibleDocumentPath(DocumentItem document) async {
    if (!_isEncryptedDirInitialized) await _initEncryptedDocumentsDirectory();

    // Reconstruct the full path to the encrypted file
    final fullEncryptedPath = p.join(
      _encryptedDocumentsDirPath,
      document.fileName,
    );
    final encryptedFile = File(fullEncryptedPath);

    if (!await encryptedFile.exists()) {
      throw Exception(
        "Encrypted document file '${document.fileName}' not found at $fullEncryptedPath.",
      );
    }

    final encrypter = _getEncrypter();
    final fileBytesWithIv = await encryptedFile.readAsBytes();

    if (fileBytesWithIv.length < 16) {
      // IV is 16 bytes
      throw Exception(
        "Encrypted file '${document.fileName}' is too short to contain IV.",
      );
    }

    // Extract IV (first 16 bytes) and ciphertext
    final iv = enc.IV(fileBytesWithIv.sublist(0, 16));
    final ciphertextBytes = Uint8List.fromList(fileBytesWithIv.sublist(16));
    final encryptedData = enc.Encrypted(ciphertextBytes);

    final decryptedBytes = encrypter.decryptBytes(encryptedData, iv: iv);

    final tempDir = await getTemporaryDirectory();
    // Use original extension for the temp file
    final tempFileName =
        '${const Uuid().v4()}${document.originalFileExtension ?? p.extension(document.name) ?? ".tmp"}';
    final tempFilePath = p.join(tempDir.path, tempFileName);

    await File(tempFilePath).writeAsBytes(decryptedBytes);
    if (kDebugMode) {
      print("Decrypted document to temporary file: $tempFilePath");
    }
    return tempFilePath; // Path to the temporary DECRYPTED file
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
      originalFileExtension: item.originalFileExtension, // Preserve extension
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
        // Reconstruct the full path to the encrypted file
        final fullPath = p.join(_encryptedDocumentsDirPath, document.fileName);
        final file = File(fullPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            "Error deleting file ${document.fileName} from filesystem: $e",
          );
        }
        // Continue even if a file deletion fails, to clear the DB
      }
    }
    await box.clear(); // Clear all entries from the Hive box
    _documents.clear(); // Clear the local list
    await _setLoading(false); // This will notify listeners
  }
}
