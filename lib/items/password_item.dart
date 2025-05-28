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
  final DateTime addedOn;

  PasswordItem({
    required this.displayName,
    required this.websiteName,
    required this.userName,
    required this.addedOn,
  });
}
