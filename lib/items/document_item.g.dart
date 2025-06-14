// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentItemAdapter extends TypeAdapter<DocumentItem> {
  @override
  final int typeId = 0;

  @override
  DocumentItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentItem(
      name: fields[0] as String,
      fileName: fields[1] as String,
      size: fields[2] as int,
      addedOn: fields[3] as DateTime,
      isLocked: fields[4] as bool,
      lastOpened: fields[5] as DateTime?,
      originalFileExtension: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.addedOn)
      ..writeByte(4)
      ..write(obj.isLocked)
      ..writeByte(5)
      ..write(obj.lastOpened)
      ..writeByte(6)
      ..write(obj.originalFileExtension);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
