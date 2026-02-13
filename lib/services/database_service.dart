import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/goal.dart';
import '../models/frequency.dart';

class DatabaseService {
  static const String _goalsBoxName = 'goals';
  static Box<Goal>? _goalsBox;
  static bool _isInitialized = false;

  /// Inicializa Hive y registra los TypeAdapters
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializa Hive (usa IndexedDB en web, sistema de archivos en móvil)
      await Hive.initFlutter();

      // Registra los TypeAdapters (generados por build_runner)
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(GoalAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FrequencyAdapter());
      }

      // Abre la caja de objetivos
      _goalsBox = await Hive.openBox<Goal>(_goalsBoxName);
      _isInitialized = true;
    } catch (e, stackTrace) {
      print('❌ Error inicializando base de datos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtiene la caja de objetivos
  static Box<Goal> get goalsBox {
    if (_goalsBox == null || !_goalsBox!.isOpen) {
      throw Exception('DatabaseService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _goalsBox!;
  }

  /// Agrega un nuevo objetivo
  static Future<void> addGoal(Goal goal) async {
    await goalsBox.put(goal.id, goal);
  }

  /// Obtiene todos los objetivos
  static List<Goal> getAllGoals() {
    return goalsBox.values.toList();
  }

  /// Obtiene un objetivo por ID
  static Goal? getGoalById(String id) {
    return goalsBox.get(id);
  }

  /// Actualiza un objetivo existente
  static Future<void> updateGoal(Goal goal) async {
    await goalsBox.put(goal.id, goal);
  }

  /// Elimina un objetivo
  static Future<void> deleteGoal(String id) async {
    await goalsBox.delete(id);
  }

  /// Obtiene objetivos por categoría
  static List<Goal> getGoalsByCategory(String category) {
    return goalsBox.values
        .where((goal) => goal.category == category)
        .toList();
  }

  /// Obtiene objetivos por frecuencia
  static List<Goal> getGoalsByFrequency(Frequency frequency) {
    return goalsBox.values
        .where((goal) => goal.frequency == frequency)
        .toList();
  }

  /// Obtiene todas las categorías únicas
  static List<String> getAllCategories() {
    return goalsBox.values
        .map((goal) => goal.category)
        .toSet()
        .toList();
  }

  /// Limpia todos los datos (útil para testing o reset)
  static Future<void> clearAllData() async {
    await goalsBox.clear();
  }

  /// Cierra todas las cajas de Hive
  static Future<void> close() async {
    await _goalsBox?.close();
  }
}
