import '../models/goal.dart';
import '../models/frequency.dart';

class StatsService {
  /// Normaliza una fecha a medianoche (00:00:00) para evitar problemas de comparación
  static DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calcula el porcentaje de cumplimiento de un objetivo basado en su frecuencia
  /// y los días que deberían haberse cumplido en un periodo
  static double calculateCompletionPercentage(Goal goal, {int days = 30}) {
    final now = _normalizeDate(DateTime.now());
    final createdNorm = _normalizeDate(goal.createdDate);
    final startDate = now.subtract(Duration(days: days));
    
    // Obtener días esperados según la frecuencia
    final expectedDays = _getExpectedDaysInPeriod(
      goal.frequency, 
      startDate, 
      now,
      createdNorm,
    );
    
    if (expectedDays == 0) return 0.0;
    
    // Contar días realmente completados en ese periodo
    int completedDays = 0;
    for (var i = 0; i < days; i++) {
      final checkDate = now.subtract(Duration(days: i));
      if (checkDate.isBefore(createdNorm)) break;
      
      if (goal.isCompletedOn(checkDate)) {
        completedDays++;
      }
    }
    
    return (completedDays / expectedDays * 100).clamp(0.0, 100.0);
  }
  
  /// Calcula cuántos días se esperaban cumplir en un periodo según la frecuencia
  static int _getExpectedDaysInPeriod(
    Frequency frequency,
    DateTime startDate,
    DateTime endDate,
    DateTime goalCreatedDate,
  ) {
    // Ajustar fechas si el objetivo fue creado después
    final effectiveStart = startDate.isAfter(goalCreatedDate) 
        ? startDate 
        : goalCreatedDate;
    
    if (effectiveStart.isAfter(endDate)) return 0;
    
    final totalDays = endDate.difference(effectiveStart).inDays + 1;
    
    switch (frequency) {
      case Frequency.daily:
        return totalDays;
        
      case Frequency.weekly:
        // 1 vez por semana
        return (totalDays / 7).ceil();
        
      case Frequency.monthly:
        // 1 vez por mes
        final months = _monthsBetween(effectiveStart, endDate);
        return months + 1;
        
      case Frequency.yearly:
        // 1 vez por año
        final years = endDate.year - effectiveStart.year;
        return years + 1;
    }
  }
  
  /// Calcula los meses entre dos fechas
  static int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }
  
  /// Obtiene datos para gráfico de tendencia de los últimos N días/semanas
  static List<CompletionDataPoint> getTrendData(
    Goal goal, {
    int points = 30,
  }) {
    final now = _normalizeDate(DateTime.now());
    final createdNorm = _normalizeDate(goal.createdDate);
    final dataPoints = <CompletionDataPoint>[];
    
    // Determinar si usar días o semanas según la frecuencia
    final useWeeks = goal.frequency == Frequency.weekly || 
                     goal.frequency == Frequency.monthly;
    final groupSize = useWeeks ? 7 : 1;
    
    for (var i = points - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i * groupSize));
      
      // Calcular cumplimiento para ese punto
      double completionRate = 0.0;
      
      if (useWeeks) {
        // Para semanas, revisar los 7 días
        int completedInWeek = 0;
        int expectedInWeek = 0;
        
        for (var d = 0; d < 7; d++) {
          final checkDate = date.add(Duration(days: d));
          if (checkDate.isAfter(now)) break;
          if (checkDate.isBefore(createdNorm)) continue;
          
          expectedInWeek++;
          if (goal.isCompletedOn(checkDate)) {
            completedInWeek++;
          }
        }
        
        completionRate = expectedInWeek > 0 
            ? (completedInWeek / expectedInWeek) * 100 
            : 0.0;
      } else {
        // Para días, revisar si está completado (incluye el día de creación)
        if (!date.isBefore(createdNorm) && !date.isAfter(now)) {
          completionRate = goal.isCompletedOn(date) ? 100.0 : 0.0;
        }
      }
      
      dataPoints.add(CompletionDataPoint(
        date: date,
        completionRate: completionRate,
      ));
    }
    
    return dataPoints;
  }
  
  /// Calcula la "Puntuación de Vida" (Life Score) del 0 al 100
  /// basada en el promedio de cumplimiento de todos los hábitos
  static double calculateLifeScore(List<Goal> goals, {int days = 30}) {
    if (goals.isEmpty) return 0.0;
    
    double totalCompletion = 0.0;
    int validGoals = 0;
    
    for (var goal in goals) {
      final completion = calculateCompletionPercentage(goal, days: days);
      totalCompletion += completion;
      validGoals++;
    }
    
    return validGoals > 0 ? totalCompletion / validGoals : 0.0;
  }
  
  /// Calcula Life Scores desglosados por frecuencia (diario, semanal, mensual)
  static FrequencyScores calculateFrequencyScores(List<Goal> goals, {int days = 30}) {
    final dailyGoals = goals.where((g) => g.frequency == Frequency.daily).toList();
    final weeklyGoals = goals.where((g) => g.frequency == Frequency.weekly).toList();
    final monthlyGoals = goals.where((g) => g.frequency == Frequency.monthly).toList();

    return FrequencyScores(
      dailyScore: _averageCompletion(dailyGoals, days: days),
      dailyCount: dailyGoals.length,
      weeklyScore: _averageCompletion(weeklyGoals, days: days),
      weeklyCount: weeklyGoals.length,
      monthlyScore: _averageCompletion(monthlyGoals, days: days),
      monthlyCount: monthlyGoals.length,
      overallScore: calculateLifeScore(goals, days: days),
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
  
  /// Obtiene estadísticas generales de un objetivo
  static GoalStats getGoalStats(Goal goal) {
    final now = _normalizeDate(DateTime.now());
    final daysActive = now.difference(_normalizeDate(goal.createdDate)).inDays + 1;
    
    // Calcular cumplimiento total
    final totalRecords = goal.records.length;
    final completedRecords = goal.records.values.where((v) => v).length;
    final totalCompletionRate = totalRecords > 0 
        ? (completedRecords / totalRecords) * 100 
        : 0.0;
    
    // Cumplimiento últimos 30 días
    final last30DaysRate = calculateCompletionPercentage(goal, days: 30);
    
    // Racha actual
    final currentStreak = goal.getCurrentStreak();
    
    // Mejor racha
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
  
  /// Calcula la mejor racha histórica
  static int _calculateBestStreak(Goal goal) {
    if (goal.records.isEmpty) return 0;
    
    int maxStreak = 0;
    int currentStreak = 0;
    
    // Ordenar fechas
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
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
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
  
  /// Obtiene estadísticas por categoría
  static Map<String, CategoryStats> getCategoryStats(List<Goal> goals) {
    final categoryMap = <String, List<Goal>>{};
    
    // Agrupar por categoría
    for (var goal in goals) {
      categoryMap.putIfAbsent(goal.category, () => []).add(goal);
    }
    
    // Calcular stats por categoría
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
  final double weeklyScore;
  final int weeklyCount;
  final double monthlyScore;
  final int monthlyCount;
  final double overallScore;
  final int totalCount;

  FrequencyScores({
    required this.dailyScore,
    required this.dailyCount,
    required this.weeklyScore,
    required this.weeklyCount,
    required this.monthlyScore,
    required this.monthlyCount,
    required this.overallScore,
    required this.totalCount,
  });
}
