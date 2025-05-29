import "package:hive/hive.dart";

part 'password_item.g.dart';

@HiveType(typeId: 1)
class PasswordItem extends HiveObject {
  @HiveField(0)
  final String displayName;
  @HiveField(1)
  final String websiteName;
  @HiveField(2)
  final String userName;
  @HiveField(3)
  final String encryptedPassword;
  @HiveField(4)
  final DateTime addedOn;
  @HiveField(5)
  final String? ivBase64;
  @HiveField(6)
  final DateTime? lastOpened;
  @HiveField(7)
  final String id;

  PasswordItem({
    required this.displayName,
    required this.websiteName,
    required this.userName,
    required this.encryptedPassword,
    required this.addedOn,
    this.ivBase64,
    this.lastOpened,
    required this.id,
  });
}
