import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeplan/models/frequency.dart';
import 'package:lifeplan/models/goal.dart';
import 'package:lifeplan/providers/goal_provider.dart';
import 'package:lifeplan/services/database_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late GoalProvider goalProvider;
  late Directory tempDir;
  late Box<Goal> goalsBox;

  setUpAll(() async {
    // 1. Configurar directorio temporal para Hive
    tempDir = await Directory.systemTemp.createTemp('lifehabit_test_');
    Hive.init(tempDir.path);

    // 2. Registrar adaptadores (esto solo se hace una vez)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GoalAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FrequencyAdapter());
    }
  });

  tearDownAll(() async {
    // Limpiar archivos de Hive y cerrar
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    // 3. Abrir box limpia para cada test
    goalsBox = await Hive.openBox<Goal>('goals');
    await goalsBox.clear();

    // Inicializar DatabaseService con el box abierto para evitar fallos de initFlutter
    DatabaseService.initializeForTest(goalsBox);

    // Inyectar el DatabaseService real (que ahora usará el box abierto)
    goalProvider = GoalProvider();
    
    // Esperar a que GoalProvider termine su carga inicial
    await Future.delayed(Duration.zero);
  });

  tearDown(() async {
    await goalsBox.close();
  });

  group('GoalProvider (Integration Test with Hive)', () {
    test('addGoal persiste el objetivo y actualiza la lista', () async {
      final goal = Goal(
        id: '1',
        title: 'Beber agua',
        category: 'Salud',
        frequency: Frequency.daily,
        createdDate: DateTime.now(),
      );

      await goalProvider.addGoal(goal);

      expect(goalProvider.goals.length, equals(1));
      expect(goalProvider.goals.first.title, equals('Beber agua'));
      
      // Verificar persistencia real en Hive
      expect(goalsBox.containsKey('1'), isTrue);
    });

    test('addGoal gestiona correctamente el orderIndex y save()', () async {
      final g1 = Goal(id: '1', title: 'G1', category: 'C1', frequency: Frequency.daily, createdDate: DateTime.now(), orderIndex: 0);
      await goalProvider.addGoal(g1);

      final g2 = Goal(id: '2', title: 'G2', category: 'C1', frequency: Frequency.daily, createdDate: DateTime.now());
      await goalProvider.addGoal(g2);

      // G2 debería estar en el índice 0 y G1 desplazado al 1
      expect(goalProvider.goals[0].id, equals('2'));
      expect(goalProvider.goals[1].id, equals('1'));
      expect(goalProvider.goals[1].orderIndex, equals(1));
      
      // Verificar que el save() funcionó en el box real
      final g1Stored = goalsBox.get('1');
      expect(g1Stored?.orderIndex, equals(1));
    });

    test('deleteGoal elimina de la lista y del box', () async {
      final goal = Goal(id: 'del-id', title: 'A eliminar', category: 'X', frequency: Frequency.daily, createdDate: DateTime.now());
      await goalProvider.addGoal(goal);
      
      // Usamos goal.id explicitly que es un String
      await goalProvider.deleteGoal(goal.id);

      expect(goalProvider.goals, isEmpty);
      expect(goalsBox.containsKey(goal.id), isFalse);
    });

    test('toggleGoalCompletion registra correctamente en el box', () async {
      final today = DateTime.now();
      final goal = Goal(id: 'check', title: 'Check', category: 'X', frequency: Frequency.daily, createdDate: today);
      await goalProvider.addGoal(goal);

      // 1. Marcar como completado
      goalProvider.toggleGoalCompletion(goal, today, true);
      expect(goal.isCompletedOn(today), isTrue);
      
      // Verificar persistencia
      expect(goalsBox.get('check')?.isCompletedOn(today), isTrue);

      // 2. Desmarcar (comprobar que vuelve a false)
      goalProvider.toggleGoalCompletion(goal, today, false);
      expect(goal.isCompletedOn(today), isFalse);

      // Verificar persistencia tras desmarcar
      expect(goalsBox.get('check')?.isCompletedOn(today), isFalse);
    });
  });
}
