import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/frequency.dart';
import '../providers/goal_provider.dart';
import 'add_goal_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Construyendo HomeScreen widget...');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LifePlan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StatsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () {
              print('🔄 Recargando objetivos...');
              context.read<GoalProvider>().loadGoals();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'about') {
                _showAboutAppDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Acerca de'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, child) {
          print('📊 Consumer builder ejecutándose... isLoading: ${goalProvider.isLoading}, goals: ${goalProvider.goals.length}');
          
          if (goalProvider.isLoading) {
            print('⏳ Mostrando loading...');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (goalProvider.goals.isEmpty) {
            print('📭 Mostrando empty state...');
            return _buildEmptyState(context);
          }

          print('📋 Mostrando lista de ${goalProvider.goals.length} objetivos...');
          return Column(
            children: [
              _buildStatsHeader(goalProvider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => goalProvider.loadGoals(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: goalProvider.goals.length,
                    itemBuilder: (context, index) {
                      final goal = goalProvider.goals[index];
                      return _buildGoalCard(context, goal, goalProvider);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          print('➕ Navegando a AddGoalScreen...');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddGoalScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Objetivo'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes objetivos aún',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comienza creando tu primer hábito u objetivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddGoalScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear mi primer objetivo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(GoalProvider goalProvider) {
    final completedToday = goalProvider.getCompletedTodayCount();
    final totalGoals = goalProvider.goals.length;
    final overallRate = goalProvider.getOverallCompletionRate();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.check_circle,
            label: 'Hoy',
            value: '$completedToday/$totalGoals',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.trending_up,
            label: 'General',
            value: '${overallRate.toStringAsFixed(0)}%',
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.flag,
            label: 'Total',
            value: '$totalGoals',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    Goal goal,
    GoalProvider goalProvider,
  ) {
    final isCompletedToday = goal.isCompletedForPeriod(DateTime.now());
    final completionRate = goal.getCompletionRate();
    final currentStreak = goal.getCurrentStreak();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showGoalDetailsDialog(context, goal, goalProvider);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Checkbox de completado
              Checkbox(
                value: isCompletedToday,
                onChanged: (value) {
                  goalProvider.toggleGoalCompletion(
                    goal,
                    DateTime.now(),
                    value ?? false,
                  );
                },
                shape: const CircleBorder(),
              ),
              const SizedBox(width: 8),

              // Información del objetivo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isCompletedToday
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompletedToday ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          goal.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _getFrequencyIcon(goal.frequency),
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          goal.frequency.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (currentStreak > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '$currentStreak ${_getStreakLabel(goal.frequency, currentStreak)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCompletionColor(completionRate)
                                .withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${completionRate.toStringAsFixed(0)}% completado',
                            style: TextStyle(
                              fontSize: 11,
                              color: _getCompletionColor(completionRate),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de opciones
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showGoalOptionsMenu(context, goal, goalProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFrequencyIcon(frequency) {
    switch (frequency) {
      case Frequency.daily:
        return Icons.today;
      case Frequency.weekly:
        return Icons.view_week;
      case Frequency.monthly:
        return Icons.calendar_month;
      case Frequency.yearly:
        return Icons.calendar_view_month;
      default:
        return Icons.calendar_today;
    }
  }

  String _getStreakLabel(Frequency frequency, int count) {
    switch (frequency) {
      case Frequency.daily:
        return count == 1 ? 'día' : 'días';
      case Frequency.weekly:
        return count == 1 ? 'semana' : 'semanas';
      case Frequency.monthly:
        return count == 1 ? 'mes' : 'meses';
      case Frequency.yearly:
        return count == 1 ? 'año' : 'años';
    }
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  void _showGoalDetailsDialog(
    BuildContext context,
    Goal goal,
    GoalProvider goalProvider,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Categoría', goal.category),
            _buildDetailRow('Frecuencia', goal.frequency.displayName),
            _buildDetailRow(
              'Creado',
              dateFormat.format(goal.createdDate),
            ),
            _buildDetailRow(
              'Racha actual',
              '${goal.getCurrentStreak()} ${_getStreakLabel(goal.frequency, goal.getCurrentStreak())}',
            ),
            _buildDetailRow(
              'Cumplimiento',
              '${goal.getCompletionRate().toStringAsFixed(1)}%',
            ),
            _buildDetailRow(
              'Total registros',
              '${goal.records.length}',
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showGoalOptionsMenu(
    BuildContext context,
    Goal goal,
    GoalProvider goalProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _showGoalDetailsDialog(context, goal, goalProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar objetivo',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, goal, goalProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Goal goal,
    GoalProvider goalProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar objetivo?'),
        content: Text('¿Estás seguro de eliminar "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await goalProvider.deleteGoal(goal.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Objetivo eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'LifePlan',
      applicationVersion: '1.0.0 (build 1)',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.track_changes, color: Colors.white, size: 36),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'App de seguimiento de hábitos y objetivos de vida.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        const Text(
          '100% offline — tus datos nunca salen de tu dispositivo.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        _buildAboutRow('Plataforma', 'Flutter 3.27.1'),
        _buildAboutRow('Base de datos', 'Hive (local)'),
        _buildAboutRow('Licencia', 'Uso personal'),
      ],
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
