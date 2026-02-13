import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../models/frequency.dart';
import '../services/database_service.dart';

/// Provider para gestionar el estado de los objetivos
class GoalProvider with ChangeNotifier {
  List<Goal> _goals = [];
  bool _isLoading = false;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;

  /// Constructor que carga los objetivos al inicializar
  GoalProvider() {
    debugPrint('🔧 GoalProvider creado');
    loadGoals();
  }

  /// Carga todos los objetivos desde la base de datos
  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();

    try {
      _goals = DatabaseService.getAllGoals();
      // Ordenar por fecha de creación (más recientes primero)
      _goals.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      debugPrint('✅ Cargados ${_goals.length} objetivos');
    } catch (e) {
      debugPrint('❌ Error cargando objetivos: $e');
      _goals = []; // Lista vacía en caso de error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega un nuevo objetivo
  Future<void> addGoal(Goal goal) async {
    try {
      await DatabaseService.addGoal(goal);
      _goals.insert(0, goal); // Agregar al inicio de la lista
      notifyListeners();
    } catch (e) {
      debugPrint('Error agregando objetivo: $e');
      rethrow;
    }
  }

  /// Actualiza un objetivo existente
  Future<void> updateGoal(Goal goal) async {
    try {
      await DatabaseService.updateGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error actualizando objetivo: $e');
      rethrow;
    }
  }

  /// Elimina un objetivo
  Future<void> deleteGoal(String goalId) async {
    try {
      await DatabaseService.deleteGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error eliminando objetivo: $e');
      rethrow;
    }
  }

  /// Marca un objetivo como completado/no completado en una fecha específica
  void toggleGoalCompletion(Goal goal, DateTime date, bool completed) {
    goal.markAsCompleted(date, completed);
    notifyListeners();
  }

  /// Obtiene objetivos por categoría
  List<Goal> getGoalsByCategory(String category) {
    return _goals.where((goal) => goal.category == category).toList();
  }

  /// Obtiene objetivos por frecuencia
  List<Goal> getGoalsByFrequency(Frequency frequency) {
    return _goals.where((goal) => goal.frequency == frequency).toList();
  }

  /// Obtiene todas las categorías únicas
  List<String> getAllCategories() {
    return _goals.map((goal) => goal.category).toSet().toList();
  }

  /// Obtiene objetivos que deben completarse hoy
  List<Goal> getTodaysGoals() {
    return _goals.where((goal) {
      // Por ahora, solo mostramos los diarios
      // TODO: Implementar lógica para semanales, mensuales, anuales
      return goal.frequency == Frequency.daily;
    }).toList();
  }

  /// Calcula el porcentaje de cumplimiento general
  double getOverallCompletionRate() {
    if (_goals.isEmpty) return 0.0;

    double totalRate = 0.0;
    for (var goal in _goals) {
      totalRate += goal.getCompletionRate();
    }

    return totalRate / _goals.length;
  }

  /// Obtiene el total de objetivos completados en su periodo actual
  int getCompletedTodayCount() {
    final today = DateTime.now();
    return _goals.where((goal) => goal.isCompletedForPeriod(today)).length;
  }
}
