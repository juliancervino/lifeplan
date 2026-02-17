import '../models/goal.dart';
import '../models/frequency.dart';

class StatsService {
  /// Normaliza una fecha a medianoche (00:00:00)
  static DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calcula estadísticas agregadas para un grupo de objetivos de la misma frecuencia
  ///
  /// NO tiene en cuenta la fecha de creación del objetivo.
  /// Para diarios: cada objetivo cuenta como 1 por día × N días
  /// Para semanales: cada objetivo cuenta como 1 por semana × N semanas
  /// Para mensuales: cada objetivo cuenta como 1 por mes × N meses
  /// Para anuales: cada objetivo cuenta como 1 por año × N años
  static FrequencyStats calculateAggregateStats(
    List<Goal> goals,
    Frequency frequency, {
    required int days,
  }) {
    final now = _normalizeDate(DateTime.now());
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

    switch (frequency) {
      case Frequency.daily:
        // Cada objetivo cuenta como 1 oportunidad por día
        final numDays = now.difference(startDate).inDays + 1;
        totalExpected = goals.length * numDays;
        for (var goal in goals) {
          for (var d = startDate; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
            if (goal.isCompletedOn(d)) totalCompleted++;
          }
        }
        break;

      case Frequency.weekly:
        // Determinar las semanas únicas en el rango
        final weeks = <String>{};
        for (var d = startDate; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          weeks.add(_weekKey(d));
        }
        totalExpected = goals.length * weeks.length;
        for (var goal in goals) {
          final completedWeeks = <String>{};
          for (var d = startDate; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
            if (goal.isCompletedOn(d)) completedWeeks.add(_weekKey(d));
          }
          totalCompleted += completedWeeks.length;
        }
        break;

      case Frequency.monthly:
        // Determinar los meses únicos en el rango
        final months = <String>{};
        for (var d = startDate; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          months.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
        }
        totalExpected = goals.length * months.length;
        for (var goal in goals) {
          final completedMonths = <String>{};
          for (var d = startDate; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
            final mk = '${d.year}-${d.month.toString().padLeft(2, '0')}';
            if (goal.isCompletedOn(d)) completedMonths.add(mk);
          }
          totalCompleted += completedMonths.length;
        }
        break;

      case Frequency.yearly:
        // Determinar los años únicos en el rango
        final years = <String>{};
        for (var d = startDate; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          years.add('${d.year}');
        }
        totalExpected = goals.length * years.length;
        for (var goal in goals) {
          final completedYears = <String>{};
          for (var d = startDate; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
            if (goal.isCompletedOn(d)) completedYears.add('${d.year}');
          }
          totalCompleted += completedYears.length;
        }
        break;
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
    final now = _normalizeDate(DateTime.now());
    final createdNorm = _normalizeDate(goal.createdDate);

    switch (goal.frequency) {
      case Frequency.daily:
        int expected = 0;
        int completed = 0;
        for (var i = 0; i < days; i++) {
          final date = now.subtract(Duration(days: i));
          if (date.isBefore(createdNorm)) break;
          expected++;
          if (goal.isCompletedOn(date)) completed++;
        }
        return expected > 0 ? (completed / expected * 100).clamp(0.0, 100.0) : 0.0;

      case Frequency.weekly:
        final startDate = now.subtract(Duration(days: days));
        final effectiveStart = startDate.isAfter(createdNorm) ? startDate : createdNorm;
        if (effectiveStart.isAfter(now)) return 0.0;

        final completedWeeks = <String>{};
        final expectedWeeks = <String>{};
        for (var d = effectiveStart; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          final wk = _weekKey(d);
          expectedWeeks.add(wk);
          if (goal.isCompletedOn(d)) completedWeeks.add(wk);
        }
        return expectedWeeks.isNotEmpty
            ? (completedWeeks.length / expectedWeeks.length * 100).clamp(0.0, 100.0)
            : 0.0;

      case Frequency.monthly:
        final startDate = now.subtract(Duration(days: days));
        final effectiveStart = startDate.isAfter(createdNorm) ? startDate : createdNorm;
        if (effectiveStart.isAfter(now)) return 0.0;

        final completedMonths = <String>{};
        final expectedMonths = <String>{};
        for (var d = effectiveStart; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          final mk = '${d.year}-${d.month.toString().padLeft(2, '0')}';
          expectedMonths.add(mk);
          if (goal.isCompletedOn(d)) completedMonths.add(mk);
        }
        return expectedMonths.isNotEmpty
            ? (completedMonths.length / expectedMonths.length * 100).clamp(0.0, 100.0)
            : 0.0;

      case Frequency.yearly:
        final startDate = now.subtract(Duration(days: days));
        final effectiveStart = startDate.isAfter(createdNorm) ? startDate : createdNorm;
        if (effectiveStart.isAfter(now)) return 0.0;

        final completedYears = <String>{};
        final expectedYears = <String>{};
        for (var d = effectiveStart; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
          final yk = '${d.year}';
          expectedYears.add(yk);
          if (goal.isCompletedOn(d)) completedYears.add(yk);
        }
        return expectedYears.isNotEmpty
            ? (completedYears.length / expectedYears.length * 100).clamp(0.0, 100.0)
            : 0.0;
    }
  }

  /// Clave de semana basada en el lunes de esa semana
  static String _weekKey(DateTime d) {
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
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
    final now = _normalizeDate(DateTime.now());
    final dailyGoals = goals.where((g) => g.frequency == Frequency.daily).toList();
    final dataPoints = <CompletionDataPoint>[];

    if (dailyGoals.isEmpty) return dataPoints;

    for (var i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // Solo contar goals que ya existían en esa fecha
      final activeGoals = dailyGoals.where(
        (g) => !date.isBefore(_normalizeDate(g.createdDate)),
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

  static double _averageCompletion(List<Goal> goals, {int days = 30}) {
    if (goals.isEmpty) return 0.0;
    final total = goals
        .map((g) => calculateCompletionPercentage(g, days: days))
        .reduce((a, b) => a + b);
    return total / goals.length;
  }

  /// Estadísticas generales de un objetivo
  static GoalStats getGoalStats(Goal goal) {
    final now = _normalizeDate(DateTime.now());
    final daysActive = now.difference(_normalizeDate(goal.createdDate)).inDays + 1;

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
