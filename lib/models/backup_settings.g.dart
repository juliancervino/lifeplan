// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupSettingsAdapter extends TypeAdapter<BackupSettings> {
  @override
  final int typeId = 2;

  @override
  BackupSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupSettings(
      autoBackupEnabled: fields[0] as bool,
      backupHour: fields[1] as int,
      backupMinute: fields[2] as int,
      maxBackupCount: fields[3] as int,
      lastBackupDate: fields[4] as DateTime?,
      googleEmail: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BackupSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.autoBackupEnabled)
      ..writeByte(1)
      ..write(obj.backupHour)
      ..writeByte(2)
      ..write(obj.backupMinute)
      ..writeByte(3)
      ..write(obj.maxBackupCount)
      ..writeByte(4)
      ..write(obj.lastBackupDate)
      ..writeByte(5)
      ..write(obj.googleEmail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
