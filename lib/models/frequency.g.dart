// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequency.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FrequencyAdapter extends TypeAdapter<Frequency> {
  @override
  final int typeId = 1;

  @override
  Frequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Frequency.daily;
      case 1:
        return Frequency.weekly;
      case 2:
        return Frequency.monthly;
      case 3:
        return Frequency.yearly;
      default:
        return Frequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, Frequency obj) {
    switch (obj) {
      case Frequency.daily:
        writer.writeByte(0);
        break;
      case Frequency.weekly:
        writer.writeByte(1);
        break;
      case Frequency.monthly:
        writer.writeByte(2);
        break;
      case Frequency.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
