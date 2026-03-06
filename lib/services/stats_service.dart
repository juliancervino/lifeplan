import '../models/goal.dart';
import '../models/frequency.dart';
import '../utils/date_utils.dart';

class StatsService {
  /// Calcula estadísticas agregadas para un grupo de objetivos de la misma frecuencia.
  ///
  /// Denominador dinámico: para cada objetivo, solo cuenta periodos desde
  /// max(inicio_del_rango, createdDate) hasta hoy.
  /// Compara createdDate ignorando la hora (solo year, month, day).
  static FrequencyStats calculateAggregateStats(
    List<Goal> goals,
    Frequency frequency, {
    required int days,
  }) {
    final now = AppDateUtils.normalize(DateTime.now());
    final startDate = now.subtract(Duration(days: days));

    if (goals.isEmpty) {
      return FrequencyStats(
        startDate: startDate,
        endDate: now,
        completed: 0,
        expected: 0,
        percentage: 0.0,
      );
    }

    int totalCompleted = 0;
    int totalExpected = 0;

    final periodKeyFn = _periodKeyFnFor(frequency);

    for (var goal in goals) {
      final createdNorm = AppDateUtils.normalize(goal.createdDate);
      // fecha_inicio_valida = max(startDate, createdDate)
      final effectiveStart = startDate.isAfter(createdNorm) ? startDate : createdNorm;

      // Si el objetivo se creó después de hoy, no cuenta
      if (effectiveStart.isAfter(now)) continue;

      if (frequency == Frequency.daily) {
        for (var d = effectiveStart; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          totalExpected++;
          if (goal.isCompletedOn(d)) totalCompleted++;
        }
      } else {
        final expectedPeriods = <String>{};
        final completedPeriods = <String>{};
        for (var d = effectiveStart; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          final key = periodKeyFn(d);
          expectedPeriods.add(key);
          if (goal.isCompletedOn(d)) completedPeriods.add(key);
        }
        totalExpected += expectedPeriods.length;
        totalCompleted += completedPeriods.length;
      }
    }

    final percentage = totalExpected > 0 
        ? (totalCompleted / totalExpected * 100).clamp(0.0, 100.0)
        : 0.0;

    return FrequencyStats(
      startDate: startDate,
      endDate: now,
      completed: totalCompleted,
      expected: totalExpected,
      percentage: percentage,
    );
  }

  /// Calcula el porcentaje de cumplimiento de un objetivo en los últimos N días.
  ///
  /// Para diarios: días marcados / días esperados.
  /// Para semanales: semanas con al menos 1 marca / semanas en el periodo.
  /// Para mensuales: meses con al menos 1 marca / meses en el periodo.
  /// Para anuales: años con al menos 1 marca / años en el periodo.
  static double calculateCompletionPercentage(Goal goal, {int days = 30}) {
    final now = AppDateUtils.normalize(DateTime.now());
    final createdNorm = AppDateUtils.normalize(goal.createdDate);

    if (goal.frequency == Frequency.daily) {
      int expected = 0;
      int completed = 0;
      for (var i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        if (date.isBefore(createdNorm)) break;
        expected++;
        if (goal.isCompletedOn(date)) completed++;
      }
      return expected > 0 ? (completed / expected * 100).clamp(0.0, 100.0) : 0.0;
    }

    return _calculatePeriodCompletionPercentage(
      goal: goal,
      now: now,
      createdNorm: createdNorm,
      days: days,
      periodKeyFn: _periodKeyFnFor(goal.frequency),
    );
  }

  /// Helper que calcula el porcentaje de cumplimiento por periodos (semanas, meses, años).
  /// Elimina la duplicación del patrón: iterar día a día, recoger claves de periodo,
  /// contar periodos completados vs esperados.
  static double _calculatePeriodCompletionPercentage({
    required Goal goal,
    required DateTime now,
    required DateTime createdNorm,
    required int days,
    required String Function(DateTime) periodKeyFn,
  }) {
    final startDate = now.subtract(Duration(days: days));
    final effectiveStart = startDate.isAfter(createdNorm) ? startDate : createdNorm;
    if (effectiveStart.isAfter(now)) return 0.0;

    final completedPeriods = <String>{};
    final expectedPeriods = <String>{};
    for (var d = effectiveStart; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
      final key = periodKeyFn(d);
      expectedPeriods.add(key);
      if (goal.isCompletedOn(d)) completedPeriods.add(key);
    }
    return expectedPeriods.isNotEmpty
        ? (completedPeriods.length / expectedPeriods.length * 100).clamp(0.0, 100.0)
        : 0.0;
  }

  /// Retorna la función de clave de periodo adecuada para la frecuencia dada.
  static String Function(DateTime) _periodKeyFnFor(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return AppDateUtils.formatKey;
      case Frequency.weekly:
        return AppDateUtils.weekKey;
      case Frequency.monthly:
        return AppDateUtils.monthKey;
      case Frequency.yearly:
        return AppDateUtils.yearKey;
    }
  }

  /// Datos para el gráfico de tendencia global de objetivos diarios.
  ///
  /// Para cada uno de los últimos N días, calcula el % de objetivos diarios
  /// completados ese día (completados / total diarios * 100).
  /// Siempre genera exactamente [days] puntos.
  static List<CompletionDataPoint> getDailyTrendData(
    List<Goal> goals, {
    int days = 30,
  }) {
    final now = AppDateUtils.normalize(DateTime.now());
    final dailyGoals = goals.where((g) => g.frequency == Frequency.daily).toList();
    final dataPoints = <CompletionDataPoint>[];

    if (dailyGoals.isEmpty) return dataPoints;

    for (var i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // Solo contar goals que ya existían en esa fecha
      final activeGoals = dailyGoals.where(
        (g) => !date.isBefore(AppDateUtils.normalize(g.createdDate)),
      ).toList();

      double rate = 0.0;
      if (activeGoals.isNotEmpty) {
        final completed = activeGoals.where((g) => g.isCompletedOn(date)).length;
        rate = completed / activeGoals.length * 100;
      }

      dataPoints.add(CompletionDataPoint(date: date, completionRate: rate));
    }

    return dataPoints;
  }

  /// Calcula la "Puntuación de Vida" (Life Score) del 0 al 100
  static double calculateLifeScore(List<Goal> goals, {int days = 30}) {
    if (goals.isEmpty) return 0.0;

    double total = 0.0;
    for (var goal in goals) {
      total += calculateCompletionPercentage(goal, days: days);
    }
    return total / goals.length;
  }

  /// Life Scores desglosados por frecuencia.
  /// Cada frecuencia usa una ventana temporal apropiada:
  /// - Diarios: últimos 60 días
  /// - Semanales: últimas 8 semanas (56 días)
  /// - Mensuales: últimos 6 meses (180 días)
  /// - Anuales: últimos 12 meses (365 días)
  static FrequencyScores calculateFrequencyScores(List<Goal> goals, {int days = 30}) {
    final dailyGoals = goals.where((g) => g.frequency == Frequency.daily).toList();
    final weeklyGoals = goals.where((g) => g.frequency == Frequency.weekly).toList();
    final monthlyGoals = goals.where((g) => g.frequency == Frequency.monthly).toList();
    final yearlyGoals = goals.where((g) => g.frequency == Frequency.yearly).toList();

    final dailyStats = calculateAggregateStats(dailyGoals, Frequency.daily, days: 60);
    final weeklyStats = calculateAggregateStats(weeklyGoals, Frequency.weekly, days: 56);
    final monthlyStats = calculateAggregateStats(monthlyGoals, Frequency.monthly, days: 180);
    final yearlyStats = calculateAggregateStats(yearlyGoals, Frequency.yearly, days: 365);

    // Promedio ponderado por cantidad de objetivos
    double overallScore = 0.0;
    if (goals.isNotEmpty) {
      double weightedSum = 0.0;
      weightedSum += dailyStats.percentage * dailyGoals.length;
      weightedSum += weeklyStats.percentage * weeklyGoals.length;
      weightedSum += monthlyStats.percentage * monthlyGoals.length;
      weightedSum += yearlyStats.percentage * yearlyGoals.length;
      overallScore = weightedSum / goals.length;
    }

    return FrequencyScores(
      dailyScore: dailyStats.percentage,
      dailyCount: dailyGoals.length,
      dailyStats: dailyStats,
      weeklyScore: weeklyStats.percentage,
      weeklyCount: weeklyGoals.length,
      weeklyStats: weeklyStats,
      monthlyScore: monthlyStats.percentage,
      monthlyCount: monthlyGoals.length,
      monthlyStats: monthlyStats,
      yearlyScore: yearlyStats.percentage,
      yearlyCount: yearlyGoals.length,
      yearlyStats: yearlyStats,
      overallScore: overallScore,
      totalCount: goals.length,
    );
  }

  /// Estadísticas generales de un objetivo
  static GoalStats getGoalStats(Goal goal) {
    final now = AppDateUtils.normalize(DateTime.now());
    final daysActive = now.difference(AppDateUtils.normalize(goal.createdDate)).inDays + 1;

    final completedRecords = goal.records.values.where((v) => v).length;
    final totalRecords = goal.records.length;
    final totalCompletionRate = totalRecords > 0
        ? (completedRecords / totalRecords) * 100
        : 0.0;

    final last30DaysRate = calculateCompletionPercentage(goal, days: 30);
    final currentStreak = goal.getCurrentStreak();
    final bestStreak = _calculateBestStreak(goal);

    return GoalStats(
      daysActive: daysActive,
      totalCompletionRate: totalCompletionRate,
      last30DaysRate: last30DaysRate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalCompletions: completedRecords,
    );
  }

  /// Mejor racha histórica
  static int _calculateBestStreak(Goal goal) {
    if (goal.records.isEmpty) return 0;

    int maxStreak = 0;
    int currentStreak = 0;

    final sortedDates = goal.records.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    DateTime? previousDate;

    for (var dateStr in sortedDates) {
      final date = DateTime.parse(dateStr);
      final completed = goal.records[dateStr] ?? false;

      if (completed) {
        if (previousDate == null ||
            date.difference(previousDate).inDays == 1) {
          currentStreak++;
          if (currentStreak > maxStreak) maxStreak = currentStreak;
        } else {
          currentStreak = 1;
        }
        previousDate = date;
      } else {
        currentStreak = 0;
        previousDate = null;
      }
    }

    return maxStreak;
  }

  /// Estadísticas por categoría
  static Map<String, CategoryStats> getCategoryStats(List<Goal> goals) {
    final categoryMap = <String, List<Goal>>{};

    for (var goal in goals) {
      categoryMap.putIfAbsent(goal.category, () => []).add(goal);
    }

    final stats = <String, CategoryStats>{};
    for (var entry in categoryMap.entries) {
      final categoryGoals = entry.value;
      final avgCompletion = categoryGoals.isEmpty
          ? 0.0
          : categoryGoals
              .map((g) => calculateCompletionPercentage(g))
              .reduce((a, b) => a + b) / categoryGoals.length;

      stats[entry.key] = CategoryStats(
        category: entry.key,
        goalCount: categoryGoals.length,
        averageCompletion: avgCompletion,
      );
    }

    return stats;
  }
}

/// Punto de datos para el gráfico de tendencia
class CompletionDataPoint {
  final DateTime date;
  final double completionRate;

  CompletionDataPoint({
    required this.date,
    required this.completionRate,
  });
}

/// Estadísticas de un objetivo
class GoalStats {
  final int daysActive;
  final double totalCompletionRate;
  final double last30DaysRate;
  final int currentStreak;
  final int bestStreak;
  final int totalCompletions;

  GoalStats({
    required this.daysActive,
    required this.totalCompletionRate,
    required this.last30DaysRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompletions,
  });
}

/// Estadísticas por categoría
class CategoryStats {
  final String category;
  final int goalCount;
  final double averageCompletion;

  CategoryStats({
    required this.category,
    required this.goalCount,
    required this.averageCompletion,
  });
}

/// Puntuaciones de vida desglosadas por frecuencia
class FrequencyScores {
  final double dailyScore;
  final int dailyCount;
  final FrequencyStats dailyStats;
  final double weeklyScore;
  final int weeklyCount;
  final FrequencyStats weeklyStats;
  final double monthlyScore;
  final int monthlyCount;
  final FrequencyStats monthlyStats;
  final double yearlyScore;
  final int yearlyCount;
  final FrequencyStats yearlyStats;
  final double overallScore;
  final int totalCount;

  FrequencyScores({
    required this.dailyScore,
    required this.dailyCount,
    required this.dailyStats,
    required this.weeklyScore,
    required this.weeklyCount,
    required this.weeklyStats,
    required this.monthlyScore,
    required this.monthlyCount,
    required this.monthlyStats,
    required this.yearlyScore,
    required this.yearlyCount,
    required this.yearlyStats,
    required this.overallScore,
    required this.totalCount,
  });
}

/// Estadísticas detalladas para una frecuencia específica
class FrequencyStats {
  final DateTime startDate;
  final DateTime endDate;
  final int completed;
  final int expected;
  final double percentage;

  FrequencyStats({
    required this.startDate,
    required this.endDate,
    required this.completed,
    required this.expected,
    required this.percentage,
  });
}
