import 'package:lifeplan/models/goal.dart';
import 'package:lifeplan/models/frequency.dart';
import 'package:lifeplan/services/stats_service.dart';

/// Ejemplos de uso del servicio de estadísticas
void main() {
  // ============================================
  // EJEMPLO 1: Calcular porcentaje de cumplimiento
  // ============================================
  
  // Crear un objetivo de ejemplo
  final goal = Goal(
    id: '1',
    title: 'Hacer ejercicio',
    category: 'Salud',
    frequency: Frequency.daily,
    createdDate: DateTime.now().subtract(Duration(days: 30)),
  );
  
  // Marcar algunos días como completados
  for (var i = 0; i < 30; i++) {
    final date = DateTime.now().subtract(Duration(days: i));
    // Completar 20 de 30 días (66.67%)
    if (i % 3 != 0) {
      goal.markAsCompleted(date, true);
    }
  }
  
  // Calcular el porcentaje de cumplimiento de los últimos 30 días
  final completion30 = StatsService.calculateCompletionPercentage(goal, days: 30);
  print('Porcentaje de cumplimiento (30 días): ${completion30.toStringAsFixed(1)}%');
  // Output: Porcentaje de cumplimiento (30 días): 66.7%
  
  // Calcular el porcentaje de cumplimiento de los últimos 7 días
  final completion7 = StatsService.calculateCompletionPercentage(goal, days: 7);
  print('Porcentaje de cumplimiento (7 días): ${completion7.toStringAsFixed(1)}%');
  
  
  // ============================================
  // EJEMPLO 2: Obtener datos para gráfico de tendencia
  // ============================================
  
  final trendData = StatsService.getTrendData(goal, points: 30);
  
  print('\n📊 Datos de tendencia (últimos 30 días):');
  for (var i = 0; i < trendData.length; i += 5) {
    final point = trendData[i];
    print('  ${point.date.day}/${point.date.month}: ${point.completionRate.toStringAsFixed(0)}%');
  }
  
  
  // ============================================
  // EJEMPLO 3: Calcular Life Score de múltiples objetivos
  // ============================================
  
  final goals = <Goal>[
    // Objetivo 1: Ejercicio diario (66% cumplimiento)
    goal,
    
    // Objetivo 2: Leer semanal (80% cumplimiento)
    Goal(
      id: '2',
      title: 'Leer 30 minutos',
      category: 'Desarrollo Personal',
      frequency: Frequency.weekly,
      createdDate: DateTime.now().subtract(Duration(days: 60)),
    ),
    
    // Objetivo 3: Meditar diario (90% cumplimiento)
    Goal(
      id: '3',
      title: 'Meditar',
      category: 'Bienestar',
      frequency: Frequency.daily,
      createdDate: DateTime.now().subtract(Duration(days: 45)),
    ),
  ];
  
  // Marcar completados para los otros objetivos
  // Leer semanal: 4 de 5 semanas (80%)
  for (var i = 0; i < 30; i += 7) {
    if (i != 14) { // Saltear una semana
      goals[1].markAsCompleted(DateTime.now().subtract(Duration(days: i)), true);
    }
  }
  
  // Meditar: 27 de 30 días (90%)
  for (var i = 0; i < 30; i++) {
    if (i % 10 != 0) { // Saltear cada 10 días
      goals[2].markAsCompleted(DateTime.now().subtract(Duration(days: i)), true);
    }
  }
  
  // Calcular la puntuación de vida
  final lifeScore = StatsService.calculateLifeScore(goals, days: 30);
  print('\n🏆 Puntuación de Vida: ${lifeScore.toStringAsFixed(0)}/100');
  // Output: Puntuación de Vida: 79/100 (promedio de 66%, 80%, 90%)
  
  
  // ============================================
  // EJEMPLO 4: Obtener estadísticas detalladas de un objetivo
  // ============================================
  
  final stats = StatsService.getGoalStats(goal);
  
  print('\n📋 Estadísticas detalladas del objetivo "${goal.title}":');
  print('  - Días activo: ${stats.daysActive}');
  print('  - Completados totales: ${stats.totalCompletions}');
  print('  - Cumplimiento total: ${stats.totalCompletionRate.toStringAsFixed(1)}%');
  print('  - Últimos 30 días: ${stats.last30DaysRate.toStringAsFixed(1)}%');
  print('  - Racha actual: ${stats.currentStreak} días');
  print('  - Mejor racha: ${stats.bestStreak} días');
  
  
  // ============================================
  // EJEMPLO 5: Estadísticas por categoría
  // ============================================
  
  final categoryStats = StatsService.getCategoryStats(goals);
  
  print('\n📁 Estadísticas por categoría:');
  categoryStats.forEach((category, stats) {
    print('  $category:');
    print('    - Objetivos: ${stats.goalCount}');
    print('    - Cumplimiento promedio: ${stats.averageCompletion.toStringAsFixed(1)}%');
  });
  
  
  // ============================================
  // EJEMPLO 6: Comparar diferentes frecuencias
  // ============================================
  
  print('\n📊 Comparación de frecuencias:');
  
  final dailyGoal = Goal(
    id: 'daily',
    title: 'Objetivo Diario',
    category: 'Test',
    frequency: Frequency.daily,
    createdDate: DateTime.now().subtract(Duration(days: 30)),
  );
  
  final weeklyGoal = Goal(
    id: 'weekly',
    title: 'Objetivo Semanal',
    category: 'Test',
    frequency: Frequency.weekly,
    createdDate: DateTime.now().subtract(Duration(days: 30)),
  );
  
  // Marcar 15 días completados para el diario
  for (var i = 0; i < 30; i += 2) {
    dailyGoal.markAsCompleted(DateTime.now().subtract(Duration(days: i)), true);
  }
  
  // Marcar 2 semanas completadas para el semanal
  weeklyGoal.markAsCompleted(DateTime.now().subtract(Duration(days: 7)), true);
  weeklyGoal.markAsCompleted(DateTime.now().subtract(Duration(days: 21)), true);
  
  final dailyCompletion = StatsService.calculateCompletionPercentage(dailyGoal, days: 30);
  final weeklyCompletion = StatsService.calculateCompletionPercentage(weeklyGoal, days: 30);
  
  print('  Diario (15/30 días): ${dailyCompletion.toStringAsFixed(1)}%');
  print('  Semanal (2/4 semanas): ${weeklyCompletion.toStringAsFixed(1)}%');
  
  
  // ============================================
  // EJEMPLO 7: Usar los datos en un Widget de Flutter
  // ============================================
  
  print('\n🎨 Ejemplo de integración en Flutter Widget:');
  print('''
  // En tu Widget:
  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context);
    final goals = goalProvider.goals;
    
    // Calcular Life Score
    final lifeScore = StatsService.calculateLifeScore(goals, days: 30);
    
    // Obtener datos de tendencia para un objetivo
    final selectedGoal = goals.first;
    final trendData = StatsService.getTrendData(selectedGoal, points: 30);
    
    return Column(
      children: [
        // Mostrar Life Score
        Text('Life Score: \${lifeScore.toStringAsFixed(0)}'),
        
        // Mostrar gráfico de tendencia
        LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: trendData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(), 
                    entry.value.completionRate,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        // Mostrar estadísticas por categoría
        ...StatsService.getCategoryStats(goals).entries.map((entry) {
          return ListTile(
            title: Text(entry.key),
            trailing: Text('\${entry.value.averageCompletion.toStringAsFixed(0)}%'),
          );
        }),
      ],
    );
  }
  ''');
}
