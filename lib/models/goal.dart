import 'package:hive/hive.dart';
import 'frequency.dart';

part 'goal.g.dart';

@HiveType(typeId: 0)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String category;

  @HiveField(3)
  Frequency frequency;

  @HiveField(4)
  DateTime createdDate;

  @HiveField(5)
  Map<String, bool> records; // Map de fecha (YYYY-MM-DD) a cumplimiento (true/false)

  @HiveField(6)
  int orderIndex;

  Goal({
    required this.id,
    required this.title,
    required this.category,
    required this.frequency,
    required this.createdDate,
    Map<String, bool>? records,
    this.orderIndex = 0,
  }) : records = records ?? {};

  /// Marca el objetivo como cumplido para una fecha específica
  void markAsCompleted(DateTime date, bool completed) {
    final dateKey = _formatDate(date);
    records[dateKey] = completed;
    save(); // Guarda en Hive automáticamente
  }

  /// Verifica si el objetivo fue cumplido en una fecha específica (clave diaria exacta)
  bool isCompletedOn(DateTime date) {
    final dateKey = _formatDate(date);
    return records[dateKey] ?? false;
  }

  /// Verifica si el objetivo está cumplido para el periodo actual según su frecuencia.
  /// - Diario: verifica el día exacto
  /// - Semanal: verifica si algún día de esa semana (lun-dom) está marcado
  /// - Mensual: verifica si algún día de ese mes está marcado
  /// - Anual: verifica si algún día de ese año está marcado
  bool isCompletedForPeriod(DateTime date) {
    switch (frequency) {
      case Frequency.daily:
        return isCompletedOn(date);
      case Frequency.weekly:
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        for (var i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          if (isCompletedOn(day)) return true;
        }
        return false;
      case Frequency.monthly:
        final monthPrefix = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        return records.entries.any((e) => e.key.startsWith(monthPrefix) && e.value);
      case Frequency.yearly:
        final yearPrefix = '${date.year}-';
        return records.entries.any((e) => e.key.startsWith(yearPrefix) && e.value);
    }
  }

  /// Obtiene el porcentaje de cumplimiento en un periodo
  double getCompletionRate({DateTime? startDate, DateTime? endDate}) {
    if (records.isEmpty) return 0.0;

    var relevantRecords = records;
    
    if (startDate != null || endDate != null) {
      relevantRecords = Map.from(records)
        ..removeWhere((key, value) {
          final date = DateTime.parse(key);
          if (startDate != null && date.isBefore(startDate)) return true;
          if (endDate != null && date.isAfter(endDate)) return true;
          return false;
        });
    }

    if (relevantRecords.isEmpty) return 0.0;

    final completedCount = relevantRecords.values.where((v) => v).length;
    return (completedCount / relevantRecords.length) * 100;
  }

  /// Obtiene el número de periodos consecutivos cumplidos (streak)
  /// según la frecuencia del objetivo
  int getCurrentStreak() {
    if (records.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      if (isCompletedForPeriod(checkDate)) {
        streak++;
        checkDate = _subtractOnePeriod(checkDate);
      } else {
        break;
      }
    }

    return streak;
  }

  /// Retrocede una unidad de periodo según la frecuencia
  DateTime _subtractOnePeriod(DateTime date) {
    switch (frequency) {
      case Frequency.daily:
        return date.subtract(const Duration(days: 1));
      case Frequency.weekly:
        return date.subtract(const Duration(days: 7));
      case Frequency.monthly:
        return DateTime(date.year, date.month - 1, date.day);
      case Frequency.yearly:
        return DateTime(date.year - 1, date.month, date.day);
    }
  }

  /// Formatea una fecha como YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Crea una copia del Goal con valores actualizados
  Goal copyWith({
    String? id,
    String? title,
    String? category,
    Frequency? frequency,
    DateTime? createdDate,
    Map<String, bool>? records,
    int? orderIndex,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      createdDate: createdDate ?? this.createdDate,
      records: records ?? Map.from(this.records),
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
