import 'package:hive/hive.dart';

part 'frequency.g.dart';

@HiveType(typeId: 1)
enum Frequency {
  @HiveField(0)
  daily,
  
  @HiveField(1)
  weekly,
  
  @HiveField(2)
  monthly,
  
  @HiveField(3)
  yearly,
}

extension FrequencyExtension on Frequency {
  String get displayName {
    switch (this) {
      case Frequency.daily:
        return 'Diario';
      case Frequency.weekly:
        return 'Semanal';
      case Frequency.monthly:
        return 'Mensual';
      case Frequency.yearly:
        return 'Anual';
    }
  }
}
