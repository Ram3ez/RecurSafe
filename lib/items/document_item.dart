import "package:hive/hive.dart";

part 'document_item.g.dart';

@HiveType(typeId: 0)
class DocumentItem extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String path;
  @HiveField(2)
  final int size; // Store size in bytes as an integer
  @HiveField(3)
  final DateTime addedOn;

  DocumentItem({
    required this.name,
    required this.path,
    required this.size,
    required this.addedOn,
  });
}
