// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasswordItemAdapter extends TypeAdapter<PasswordItem> {
  @override
  final int typeId = 1;

  @override
  PasswordItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasswordItem(
      displayName: fields[0] as String,
      websiteName: fields[1] as String,
      userName: fields[2] as String,
      encryptedPassword: fields[3] as String,
      addedOn: fields[4] as DateTime,
      ivBase64: fields[5] as String?,
      lastOpened: fields[6] as DateTime?,
      id: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PasswordItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.displayName)
      ..writeByte(1)
      ..write(obj.websiteName)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.encryptedPassword)
      ..writeByte(4)
      ..write(obj.addedOn)
      ..writeByte(5)
      ..write(obj.ivBase64)
      ..writeByte(6)
      ..write(obj.lastOpened)
      ..writeByte(7)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
