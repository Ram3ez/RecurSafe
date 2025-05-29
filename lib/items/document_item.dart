import "package:hive/hive.dart";

part 'document_item.g.dart';

/// The name of the subdirectory within the app's documents directory
/// where all user documents are stored.
const String kDocumentsSubDir = "recursafe_documents";

@HiveType(typeId: 0)
class DocumentItem extends HiveObject {
  @HiveField(0)
  final String name; // User-facing display name
  @HiveField(1)
  final String fileName; // Stores only the filename, e.g., "mydoc.pdf"
  @HiveField(2)
  final int size; // Store size in bytes as an integer
  @HiveField(3)
  final DateTime addedOn;
  @HiveField(4)
  bool isLocked;
  @HiveField(5) // New field for last opened date
  final DateTime? lastOpened;

  DocumentItem({
    required this.name,
    required this.fileName, // Changed from path
    required this.size,
    required this.addedOn,
    this.isLocked = false, // Default to not locked
    this.lastOpened, // Optional parameter for flexibility
  }); // Initialize with addedOn if not provided
}
