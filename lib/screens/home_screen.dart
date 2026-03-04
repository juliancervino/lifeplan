import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/goal.dart';
import '../models/frequency.dart';
import '../providers/goal_provider.dart';
import '../providers/settings_provider.dart';
import 'add_goal_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _selectedDate;
  bool _isCalendarVisible = false;
  Frequency? _selectedFrequency; // null = Todos

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(DateTime.now());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Al volver a la app, comprobar si hay backup pendiente
      context.read<SettingsProvider>().checkAndRunPendingBackup();
    }
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _isToday {
    final now = _normalizeDate(DateTime.now());
    switch (_selectedFrequency) {
      case null:
      case Frequency.daily:
        return isSameDay(_selectedDate, now);
      case Frequency.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final selWeekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        return isSameDay(weekStart, selWeekStart);
      case Frequency.monthly:
        return _selectedDate.year == now.year && _selectedDate.month == now.month;
      case Frequency.yearly:
        return _selectedDate.year == now.year;
    }
  }

  String _formatSelectedDate() {
    final now = _normalizeDate(DateTime.now());
    final yesterday = now.subtract(const Duration(days: 1));

    switch (_selectedFrequency) {
      case null:
      case Frequency.daily:
        if (isSameDay(_selectedDate, now)) return 'Hoy';
        if (isSameDay(_selectedDate, yesterday)) return 'Ayer';
        return DateFormat('d MMM yyyy', 'es').format(_selectedDate);
      case Frequency.weekly:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'es').format(weekStart)} - ${DateFormat('d MMM', 'es').format(weekEnd)}';
      case Frequency.monthly:
        final formatted = DateFormat('MMMM yyyy', 'es').format(_selectedDate);
        return formatted[0].toUpperCase() + formatted.substring(1);
      case Frequency.yearly:
        return '${_selectedDate.year}';
    }
  }

  void _goToPrevious() {
    setState(() {
      switch (_selectedFrequency) {
        case null:
        case Frequency.daily:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case Frequency.weekly:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case Frequency.monthly:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
        case Frequency.yearly:
          _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month, _selectedDate.day);
          break;
      }
    });
  }

  void _goToNext() {
    if (!_isToday) {
      setState(() {
        switch (_selectedFrequency) {
          case null:
          case Frequency.daily:
            _selectedDate = _selectedDate.add(const Duration(days: 1));
            break;
          case Frequency.weekly:
            _selectedDate = _selectedDate.add(const Duration(days: 7));
            break;
          case Frequency.monthly:
            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
            break;
          case Frequency.yearly:
            _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
            break;
        }
      });
    }
  }

  void _goToToday() {
    setState(() {
      _selectedDate = _normalizeDate(DateTime.now());
      _isCalendarVisible = false;
    });
  }

  List<Goal> _filterGoals(List<Goal> goals) {
    if (_selectedFrequency == null) return goals;
    return goals.where((g) => g.frequency == _selectedFrequency).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'about') {
                _showAboutAppDialog(context);
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Configuración'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
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
          if (goalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (goalProvider.goals.isEmpty) {
            return _buildEmptyState(context);
          }

          final filteredGoals = _filterGoals(goalProvider.goals);

          return Column(
            children: [
              // Filtro de frecuencia
              _buildFrequencyFilter(),
              // Barra de navegación de fecha
              _buildDateNavigationBar(),
              // Calendario expandible (solo para Todos / Diarios)
              if (_selectedFrequency == null || _selectedFrequency == Frequency.daily)
                _buildCalendarView(goalProvider),
              // Cabecera de estadísticas
              _buildStatsHeader(goalProvider, filteredGoals),
              // Lista de objetivos
              Expanded(
                child: filteredGoals.isEmpty
                    ? Center(
                        child: Text(
                          _selectedFrequency != null
                              ? 'No hay objetivos ${_selectedFrequency!.displayName.toLowerCase()}es'
                              : 'No hay objetivos',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: filteredGoals.length,
                        onReorder: (oldIndex, newIndex) {
                          // Mapear indices filtrados a indices reales
                          if (newIndex > oldIndex) newIndex--;
                          final realOldIndex = goalProvider.goals.indexOf(filteredGoals[oldIndex]);
                          final realNewIndex = goalProvider.goals.indexOf(filteredGoals[newIndex]);
                          goalProvider.reorderGoals(realOldIndex, realNewIndex > realOldIndex ? realNewIndex + 1 : realNewIndex);
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final goal = filteredGoals[index];
                          return _buildGoalCard(
                            context, goal, goalProvider,
                            key: ValueKey(goal.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
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

  // ─── Frequency Filter ───────────────────────────────────────

  Widget _buildFrequencyFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', null),
            const SizedBox(width: 6),
            _buildFilterChip('📅 Diarios', Frequency.daily),
            const SizedBox(width: 6),
            _buildFilterChip('📆 Semanales', Frequency.weekly),
            const SizedBox(width: 6),
            _buildFilterChip('🗓️ Mensuales', Frequency.monthly),
            const SizedBox(width: 6),
            _buildFilterChip('🌟 Anuales', Frequency.yearly),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Frequency? frequency) {
    final isSelected = _selectedFrequency == frequency;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? Colors.white : Colors.deepPurple.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFrequency = selected ? frequency : null;
          _selectedDate = _normalizeDate(DateTime.now());
          _isCalendarVisible = false;
        });
      },
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.deepPurple.shade50,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // ─── Date Navigation Bar ─────────────────────────────────────

  Widget _buildDateNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flecha izquierda
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: _goToPrevious,
            tooltip: 'Anterior',
          ),
          // Fecha (tap para abrir calendario)
          GestureDetector(
            onTap: () {
              setState(() {
                _isCalendarVisible = !_isCalendarVisible;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isCalendarVisible
                    ? Colors.deepPurple.shade100
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCalendarVisible
                        ? Icons.calendar_month
                        : Icons.calendar_today,
                    size: 18,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSelectedDate(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Flecha derecha (deshabilitada si es periodo actual)
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 28,
              color: _isToday ? Colors.grey.shade300 : null,
            ),
            onPressed: _isToday ? null : _goToNext,
            tooltip: 'Siguiente',
          ),
          // Botón "Hoy" (visible solo si no estamos en hoy)
          if (!_isToday)
            TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today, size: 16),
              label: const Text('Hoy', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Calendar View ───────────────────────────────────────────

  Widget _buildCalendarView(GoalProvider goalProvider) {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: _buildCalendarBody(goalProvider),
      crossFadeState: _isCalendarVisible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildCalendarBody(GoalProvider goalProvider) {
    final now = _normalizeDate(DateTime.now());
    final earliestGoal = goalProvider.getEarliestCreatedDate();
    final earliest = earliestGoal != null
        ? _normalizeDate(earliestGoal).subtract(const Duration(days: 365))
        : now.subtract(const Duration(days: 730));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'es',
        firstDay: earliest,
        lastDay: now,
        focusedDay: _selectedDate.isAfter(now) ? now : _selectedDate,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple.shade800,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Colors.deepPurple.shade600,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Colors.deepPurple.shade600,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = _normalizeDate(selectedDay);
            _isCalendarVisible = false;
          });
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildCalendarDayCell(day, goalProvider, isSelected: false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildCalendarDayCell(
              day,
              goalProvider,
              isSelected: isSameDay(day, _selectedDate),
              isToday: true,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildCalendarDayCell(
              day,
              goalProvider,
              isSelected: true,
              isToday: isSameDay(day, _normalizeDate(DateTime.now())),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarDayCell(
    DateTime day,
    GoalProvider goalProvider, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final ratio = goalProvider.getDailyGoalCompletionRatio(day);

    Color? bgColor;
    Color textColor = Colors.black87;

    if (ratio >= 0) {
      // Hay goals diarios → colorear según ratio
      bgColor = Color.lerp(
        Colors.red.shade300,
        Colors.green.shade400,
        ratio,
      )!.withAlpha((80 + (ratio * 120)).toInt());
    }

    if (isSelected) {
      bgColor = Colors.deepPurple;
      textColor = Colors.white;
    } else if (isToday) {
      textColor = Colors.deepPurple;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: Colors.deepPurple, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  // ─── Existing widgets (updated for selectedDate) ─────────────

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

  Widget _buildStatsHeader(GoalProvider goalProvider, List<Goal> filteredGoals) {
    final completedCount = filteredGoals.where((g) => g.isCompletedForPeriod(_selectedDate)).length;
    final totalGoals = filteredGoals.length;
    final dayRate = totalGoals > 0 ? (completedCount / totalGoals * 100) : 0.0;

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
            label: _isToday ? 'Hoy' : _formatSelectedDate(),
            value: '$completedCount/$totalGoals',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.trending_up,
            label: 'Cumplimiento',
            value: '${dayRate.toStringAsFixed(0)}%',
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
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    Goal goal,
    GoalProvider goalProvider, {
    Key? key,
  }) {
    final isCompleted = goal.isCompletedForPeriod(_selectedDate);
    final completionRate = goal.getCompletionRate();
    final currentStreak = goal.getCurrentStreak();
    final isDisabled = goal.isBeforeCreation(_selectedDate);

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: isDisabled ? 0.5 : 2,
      child: Opacity(
        opacity: isDisabled ? 0.45 : 1.0,
        child: InkWell(
          onTap: () {
            if (isDisabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Este objetivo aún no se había creado en esta fecha'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            _showGoalDetailsDialog(context, goal, goalProvider);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Checkbox de completado (bloqueado si fecha < createdDate)
                Checkbox(
                  value: isDisabled ? false : isCompleted,
                  onChanged: isDisabled
                      ? null
                      : (value) {
                          final success = goalProvider.toggleGoalCompletion(
                            goal,
                            _selectedDate,
                            value ?? false,
                          );
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Este objetivo aún no se había creado en esta fecha'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
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
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted ? Colors.grey : null,
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
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

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

  // ─── Dialogs ─────────────────────────────────────────────────

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
              leading: const Icon(Icons.edit),
              title: const Text('Editar nombre'),
              onTap: () {
                Navigator.pop(context);
                _showEditGoalDialog(context, goal, goalProvider);
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

  void _showEditGoalDialog(
    BuildContext context,
    Goal goal,
    GoalProvider goalProvider,
  ) {
    final controller = TextEditingController(text: goal.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre del objetivo',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != goal.title) {
                goalProvider.renameGoal(goal, newTitle);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre actualizado')),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
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
