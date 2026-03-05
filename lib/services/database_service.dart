import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';
import '../models/frequency.dart';

class DatabaseService {
  static const String _goalsBoxName = 'goals';
  static Box<Goal>? _goalsBox;
  static bool _isInitialized = false;

  // Singleton pattern for dependency injection
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Inicializa la base de datos para pruebas con una caja ya abierta
  static void initializeForTest(Box<Goal> box) {
    _goalsBox = box;
    _isInitialized = true;
  }

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
  Box<Goal> get goalsBox {
    if (_goalsBox == null || !_goalsBox!.isOpen) {
      throw Exception('DatabaseService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _goalsBox!;
  }

  /// Agrega un nuevo objetivo (Static wrapper)
  static Future<void> addGoal(Goal goal) => _instance.addGoalImpl(goal);

  /// Agrega un nuevo objetivo (Instance implementation)
  Future<void> addGoalImpl(Goal goal) async {
    await goalsBox.put(goal.id, goal);
  }

  /// Obtiene todos los objetivos (Static wrapper)
  static List<Goal> getAllGoals() => _instance.getAllGoalsImpl();

  /// Obtiene todos los objetivos (Instance implementation)
  List<Goal> getAllGoalsImpl() {
    return goalsBox.values.toList();
  }

  /// Obtiene un objetivo por ID (Static wrapper)
  static Goal? getGoalById(String id) => _instance.getGoalByIdImpl(id);

  /// Obtiene un objetivo por ID (Instance implementation)
  Goal? getGoalByIdImpl(String id) {
    return goalsBox.get(id);
  }

  /// Actualiza un objetivo existente (Static wrapper)
  static Future<void> updateGoal(Goal goal) => _instance.updateGoalImpl(goal);

  /// Actualiza un objetivo existente (Instance implementation)
  Future<void> updateGoalImpl(Goal goal) async {
    await goalsBox.put(goal.id, goal);
  }

  /// Elimina un objetivo (Static wrapper)
  static Future<void> deleteGoal(String id) => _instance.deleteGoalImpl(id);

  /// Elimina un objetivo (Instance implementation)
  Future<void> deleteGoalImpl(String id) async {
    await goalsBox.delete(id);
  }

  /// Obtiene objetivos por categoría (Static wrapper)
  static List<Goal> getGoalsByCategory(String category) => _instance.getGoalsByCategoryImpl(category);

  /// Obtiene objetivos por categoría (Instance implementation)
  List<Goal> getGoalsByCategoryImpl(String category) {
    return goalsBox.values
        .where((goal) => goal.category == category)
        .toList();
  }

  /// Obtiene objetivos por frecuencia (Static wrapper)
  static List<Goal> getGoalsByFrequency(Frequency frequency) => _instance.getGoalsByFrequencyImpl(frequency);

  /// Obtiene objetivos por frecuencia (Instance implementation)
  List<Goal> getGoalsByFrequencyImpl(Frequency frequency) {
    return goalsBox.values
        .where((goal) => goal.frequency == frequency)
        .toList();
  }

  /// Obtiene todas las categorías únicas (Static wrapper)
  static List<String> getAllCategories() => _instance.getAllCategoriesImpl();

  /// Obtiene todas las categorías únicas (Instance implementation)
  List<String> getAllCategoriesImpl() {
    return goalsBox.values
        .map((goal) => goal.category)
        .toSet()
        .toList();
  }

  /// Limpia todos los datos (Static wrapper)
  static Future<void> clearAllData() => _instance.clearAllDataImpl();

  /// Limpia todos los datos (Instance implementation)
  Future<void> clearAllDataImpl() async {
    await goalsBox.clear();
  }

  /// Cierra todas las cajas de Hive (Static wrapper)
  static Future<void> close() => _instance.closeImpl();

  /// Cierra todas las cajas de Hive (Instance implementation)
  Future<void> closeImpl() async {
    await _goalsBox?.close();
  }
}
