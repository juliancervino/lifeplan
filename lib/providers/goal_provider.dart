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
      // Ordenar por orderIndex, luego por fecha de creación como fallback
      _goals.sort((a, b) {
        if (a.orderIndex != b.orderIndex) {
          return a.orderIndex.compareTo(b.orderIndex);
        }
        return b.createdDate.compareTo(a.createdDate);
      });
      // Asignar orderIndex a goals antiguos que tengan todos 0
      _assignOrderIndexIfNeeded();
      debugPrint('✅ Cargados ${_goals.length} objetivos');
    } catch (e) {
      debugPrint('❌ Error cargando objetivos: $e');
      _goals = []; // Lista vacía en caso de error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Asigna orderIndex incremental a goals que aún no lo tienen
  void _assignOrderIndexIfNeeded() {
    if (_goals.length > 1 && _goals.every((g) => g.orderIndex == 0)) {
      for (var i = 0; i < _goals.length; i++) {
        _goals[i].orderIndex = i;
        _goals[i].save();
      }
    }
  }

  /// Agrega un nuevo objetivo
  Future<void> addGoal(Goal goal) async {
    try {
      // Asignar orderIndex 0 (se inserta al inicio) y desplazar los demás
      goal.orderIndex = 0;
      for (var g in _goals) {
        g.orderIndex++;
        g.save();
      }
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

  /// Renombra un objetivo
  Future<void> renameGoal(Goal goal, String newTitle) async {
    goal.title = newTitle;
    goal.save();
    notifyListeners();
  }

  /// Reordena los objetivos tras un drag & drop
  void reorderGoals(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _goals.removeAt(oldIndex);
    _goals.insert(newIndex, item);

    // Actualizar orderIndex en todos
    for (var i = 0; i < _goals.length; i++) {
      _goals[i].orderIndex = i;
      _goals[i].save();
    }
    notifyListeners();
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
