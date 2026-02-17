import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/goal.dart';
import '../models/frequency.dart';
import '../providers/goal_provider.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  final Goal? selectedGoal;
  
  const StatsScreen({super.key, this.selectedGoal});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Goal? _selectedGoal;
  int _trendDays = 30;
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScreenshotController _trendScreenshotController = ScreenshotController();
  bool _isSharing = false;
  bool _isSharingTrend = false;
  
  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.selectedGoal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Estadísticas'),
        elevation: 0,
      ),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, child) {
          final goals = goalProvider.goals;
          
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  Text(
                    'No hay objetivos para analizar',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primer objetivo para ver estadísticas',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Life Score Card
                _buildLifeScoreCard(goals),
                const SizedBox(height: 24),
                
                // Tendencia de cumplimiento diario (global)
                _buildDailyTrendChart(goals),
                const SizedBox(height: 24),

                // Selector de objetivo para detalles
                _buildGoalSelector(goals),
                const SizedBox(height: 24),
                
                // Si hay un objetivo seleccionado, mostrar sus stats
                if (_selectedGoal != null) ...[
                  _buildGoalDetailsCard(_selectedGoal!),
                  const SizedBox(height: 24),
                ],
                
                // Estadísticas por categoría
                _buildCategoryStats(goals),
                const SizedBox(height: 24),
                
                // Resumen general
                _buildOverallSummary(goals),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLifeScoreCard(List<Goal> goals) {
    final scores = StatsService.calculateFrequencyScores(goals, days: 30);
    final overallColor = _getScoreColor(scores.overallScore);
    
    return Screenshot(
      controller: _screenshotController,
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header con título y botón compartir
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '🏆 Puntuación de Vida',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    onPressed: _isSharing ? null : _shareLifeScore,
                    tooltip: 'Compartir con amigos',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Score general grande
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [overallColor.withOpacity(0.8), overallColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      scores.overallScore.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '/ 100  General',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreMessage(scores.overallScore),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tarjetas de frecuencia (2x2 grid)
              Row(
                children: [
                  Expanded(
                    child: _buildFrequencyScoreTile(
                      emoji: '📅',
                      label: 'Diarios',
                      score: scores.dailyScore,
                      count: scores.dailyCount,
                      period: '60 días',
                      stats: scores.dailyStats,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFrequencyScoreTile(
                      emoji: '📆',
                      label: 'Semanales',
                      score: scores.weeklyScore,
                      count: scores.weeklyCount,
                      period: '8 sem.',
                      stats: scores.weeklyStats,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFrequencyScoreTile(
                      emoji: '🗓️',
                      label: 'Mensuales',
                      score: scores.monthlyScore,
                      count: scores.monthlyCount,
                      period: '6 meses',
                      stats: scores.monthlyStats,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFrequencyScoreTile(
                      emoji: '🌟',
                      label: 'Anuales',
                      score: scores.yearlyScore,
                      count: scores.yearlyCount,
                      period: '12 meses',
                      stats: scores.yearlyStats,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Basado en ${scores.totalCount} ${scores.totalCount == 1 ? 'objetivo' : 'objetivos'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyScoreTile({
    required String emoji,
    required String label,
    required double score,
    required int count,
    required String period,
    required FrequencyStats stats,
  }) {
    final color = count > 0 ? _getScoreColor(score) : Colors.grey;

    return InkWell(
      onTap: count > 0 ? () => _showStatsDetail(context, label, stats, period) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(75)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              count > 0 ? '${score.toStringAsFixed(0)}%' : '—',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: count > 0 ? color : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              '$count obj. · $period',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsDetail(BuildContext context, String label, FrequencyStats stats, String period) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estadísticas: $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periodo evaluado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Inicio: ${DateFormat('dd/MM/yyyy').format(stats.startDate)}'),
            Text('Fin: ${DateFormat('dd/MM/yyyy').format(stats.endDate)}'),
            const Divider(height: 24),
            Text(
              'Resultados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Completados: ${stats.completed}'),
            Text('Esperados: ${stats.expected}'),
            Text(
              'Porcentaje: ${stats.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _getScoreColor(stats.percentage),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalSelector(List<Goal> goals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ver detalles de:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Goal?>(
              value: _selectedGoal,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Selecciona un objetivo'),
              items: goals.map((goal) {
                return DropdownMenuItem<Goal?>(
                  value: goal,
                  child: Text(
                    goal.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (goal) {
                setState(() {
                  _selectedGoal = goal;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoalDetailsCard(Goal goal) {
    final stats = StatsService.getGoalStats(goal);
    final completion30Days = StatsService.calculateCompletionPercentage(goal, days: 30);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.frequency.displayName,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '📁 ${goal.category}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 24),
            
            // Grid de estadísticas
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatItem(
                  icon: '📅',
                  label: 'Días activo',
                  value: '${stats.daysActive}',
                ),
                _buildStatItem(
                  icon: '✅',
                  label: 'Completados',
                  value: '${stats.totalCompletions}',
                ),
                _buildStatItem(
                  icon: '📈',
                  label: 'Últimos 30 días',
                  value: '${completion30Days.toStringAsFixed(0)}%',
                ),
                _buildStatItem(
                  icon: '🔥',
                  label: 'Racha actual',
                  value: '${stats.currentStreak}',
                ),
                _buildStatItem(
                  icon: '🏅',
                  label: 'Mejor racha',
                  value: '${stats.bestStreak}',
                ),
                _buildStatItem(
                  icon: '💯',
                  label: 'Total',
                  value: '${stats.totalCompletionRate.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyTrendChart(List<Goal> goals) {
    final dailyGoals = goals.where((g) => g.frequency == Frequency.daily).toList();

    if (dailyGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    final trendData = StatsService.getDailyTrendData(goals, days: _trendDays);

    if (trendData.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.completionRate);
    }).toList();

    // Calcular promedio del periodo
    final avgRate = trendData.map((d) => d.completionRate).reduce((a, b) => a + b) / trendData.length;

    return Screenshot(
      controller: _trendScreenshotController,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '📊 Tendencia de Cumplimiento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSharingTrend
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share, size: 20),
                    onPressed: _isSharingTrend ? null : () => _shareTrendChart(goals),
                    tooltip: 'Compartir gráfico',
                  ),
                  DropdownButton<int>(
                    value: _trendDays,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7d')),
                      DropdownMenuItem(value: 14, child: Text('14d')),
                      DropdownMenuItem(value: 30, child: Text('30d')),
                      DropdownMenuItem(value: 60, child: Text('60d')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _trendDays = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${dailyGoals.length} objetivos diarios · Promedio: ${avgRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300]!,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (_trendDays / 5).floorToDouble().clamp(1, double.infinity),
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= trendData.length) {
                              return const SizedBox();
                            }
                            final date = trendData[idx].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('d/M').format(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                        left: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    minX: 0,
                    maxX: (trendData.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: spots.length <= 30,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.blue,
                              strokeWidth: 0,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withAlpha(25),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt().clamp(0, trendData.length - 1);
                            final date = trendData[idx].date;
                            return LineTooltipItem(
                              '${DateFormat('d MMM').format(date)}\n${spot.y.toStringAsFixed(0)}%',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareTrendChart(List<Goal> goals) async {
    setState(() {
      _isSharingTrend = true;
    });

    try {
      final image = await _trendScreenshotController.capture(pixelRatio: 2.0);
      if (image == null) throw Exception('No se pudo capturar la imagen');

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/lifeplan_trend_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      final dailyGoals = goals.where((g) => g.frequency == Frequency.daily).toList();
      final trendData = StatsService.getDailyTrendData(goals, days: _trendDays);
      final avgRate = trendData.isNotEmpty
          ? trendData.map((d) => d.completionRate).reduce((a, b) => a + b) / trendData.length
          : 0.0;

      final message = '''📊 Mi Tendencia de Cumplimiento — Últimos $_trendDays días

📅 ${dailyGoals.length} objetivos diarios
📈 Promedio: ${avgRate.toStringAsFixed(0)}%

¡Sigue tu progreso con LifePlan!''';

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: message,
        subject: 'Mi Tendencia — LifePlan',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingTrend = false;
        });
      }
    }
  }

  /// Captura el bloque de Puntuación de Vida y lo comparte
  Future<void> _shareLifeScore() async {
    setState(() {
      _isSharing = true;
    });
    
    try {
      final image = await _screenshotController.capture(
        pixelRatio: 2.0,
      );
      
      if (image == null) {
        throw Exception('No se pudo capturar la imagen');
      }
      
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/lifeplan_score_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      
      // Obtener scores para el mensaje
      final goals = context.read<GoalProvider>().goals;
      final scores = StatsService.calculateFrequencyScores(goals, days: 30);
      
      final parts = <String>[];
      if (scores.dailyCount > 0) {
        parts.add('📅 Diarios (${scores.dailyCount}): ${scores.dailyScore.toStringAsFixed(0)}%');
      }
      if (scores.weeklyCount > 0) {
        parts.add('📆 Semanales (${scores.weeklyCount}): ${scores.weeklyScore.toStringAsFixed(0)}%');
      }
      if (scores.monthlyCount > 0) {
        parts.add('🗓️ Mensuales (${scores.monthlyCount}): ${scores.monthlyScore.toStringAsFixed(0)}%');
      }
      if (scores.yearlyCount > 0) {
        parts.add('🌟 Anuales (${scores.yearlyCount}): ${scores.yearlyScore.toStringAsFixed(0)}%');
      }
      
      final message = '''🏆 Mi Puntuación de Vida: ${scores.overallScore.toStringAsFixed(0)}/100

${parts.join('\n')}

📊 ${scores.totalCount} objetivos
¡Sigue tu progreso con LifePlan!''';
      
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: message,
        subject: 'Mi Puntuación de Vida — LifePlan',
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
  
  Widget _buildCategoryStats(List<Goal> goals) {
    final categoryStats = StatsService.getCategoryStats(goals);
    
    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📁 Estadísticas por Categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryStats.entries.map((entry) {
              final stats = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stats.category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${stats.goalCount} ${stats.goalCount == 1 ? 'objetivo' : 'objetivos'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: stats.averageCompletion / 100,
                      backgroundColor: Colors.grey[200],
                      color: _getScoreColor(stats.averageCompletion),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.averageCompletion.toStringAsFixed(0)}% cumplimiento promedio',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverallSummary(List<Goal> goals) {
    final totalGoals = goals.length;
    final todayGoals = goals.where((g) => g.isCompletedOn(DateTime.now())).length;
    final activeGoals = goals.where((g) => g.getCurrentStreak() > 0).length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Resumen General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Total de objetivos', '$totalGoals'),
            _buildSummaryRow('Completados hoy', '$todayGoals / $totalGoals'),
            _buildSummaryRow('Con racha activa', '$activeGoals'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
  
  String _getScoreMessage(double score) {
    if (score >= 90) return '¡Excelente! Estás en la cima 🌟';
    if (score >= 80) return '¡Muy bien! Sigue así 💪';
    if (score >= 70) return 'Buen trabajo, vas por buen camino 👍';
    if (score >= 60) return 'Progreso constante, ¡no te rindas! 🚀';
    if (score >= 50) return 'Hay espacio para mejorar 📈';
    if (score >= 40) return 'Vamos, ¡tú puedes hacerlo mejor! 💡';
    return 'Es momento de retomar el control 🎯';
  }
}
