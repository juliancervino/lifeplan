import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'services/database_service.dart';
import 'models/goal.dart';
import 'models/frequency.dart';

/// Ejemplo de uso del DatabaseService y modelo Goal
/// Este archivo muestra cómo interactuar con la base de datos Hive

void exampleUsage() async {
  // 1. Inicializar la base de datos (ya debe estar hecho en main.dart)
  // await DatabaseService.initialize();

  const uuid = Uuid();

  // 2. Crear un nuevo objetivo
  final newGoal = Goal(
    id: uuid.v4(),
    title: 'Hacer ejercicio',
    category: 'Salud',
    frequency: Frequency.daily,
    createdDate: DateTime.now(),
  );

  // 3. Guardar el objetivo en la base de datos
  await DatabaseService.addGoal(newGoal);
  debugPrint('✅ Objetivo creado: ${newGoal.title}');

  // 4. Marcar como cumplido hoy
  newGoal.markAsCompleted(DateTime.now(), true);
  debugPrint('✅ Objetivo marcado como cumplido hoy');

  // 5. Obtener todos los objetivos
  final allGoals = DatabaseService.getAllGoals();
  debugPrint('📋 Total de objetivos: ${allGoals.length}');

  // 6. Obtener objetivos por categoría
  final healthGoals = DatabaseService.getGoalsByCategory('Salud');
  debugPrint('💪 Objetivos de salud: ${healthGoals.length}');

  // 7. Obtener objetivos diarios
  final dailyGoals = DatabaseService.getGoalsByFrequency(Frequency.daily);
  debugPrint('📅 Objetivos diarios: ${dailyGoals.length}');

  // 8. Verificar cumplimiento
  final isCompletedToday = newGoal.isCompletedOn(DateTime.now());
  debugPrint('✓ ¿Cumplido hoy?: $isCompletedToday');

  // 9. Obtener porcentaje de cumplimiento
  final completionRate = newGoal.getCompletionRate();
  debugPrint('📊 Tasa de cumplimiento: ${completionRate.toStringAsFixed(1)}%');

  // 10. Obtener racha actual
  final streak = newGoal.getCurrentStreak();
  debugPrint('🔥 Racha actual: $streak días');

  // 11. Actualizar un objetivo
  final updatedGoal = newGoal.copyWith(title: 'Hacer ejercicio 30 min');
  await DatabaseService.updateGoal(updatedGoal);
  debugPrint('✏️ Objetivo actualizado');

  // 12. Obtener un objetivo por ID
  final foundGoal = DatabaseService.getGoalById(newGoal.id);
  debugPrint('🔍 Objetivo encontrado: ${foundGoal?.title}');

  // 13. Obtener todas las categorías
  final categories = DatabaseService.getAllCategories();
  debugPrint('📂 Categorías: ${categories.join(", ")}');

  // 14. Eliminar un objetivo (descomenta para probar)
  // await DatabaseService.deleteGoal(newGoal.id);
  // debugPrint('🗑️ Objetivo eliminado');
}

/// Widget de demostración que muestra los datos en la UI
class DatabaseExampleScreen extends StatefulWidget {
  const DatabaseExampleScreen({super.key});

  @override
  State<DatabaseExampleScreen> createState() => _DatabaseExampleScreenState();
}

class _DatabaseExampleScreenState extends State<DatabaseExampleScreen> {
  @override
  Widget build(BuildContext context) {
    final goals = DatabaseService.getAllGoals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo de Base de Datos'),
      ),
      body: goals.isEmpty
          ? const Center(
              child: Text('No hay objetivos. Crea uno usando el botón +'),
            )
          : ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(goal.title),
                    subtitle: Text(
                      '${goal.category} • ${goal.frequency.displayName}\n'
                      'Racha: ${goal.getCurrentStreak()} días • '
                      'Cumplimiento: ${goal.getCompletionRate().toStringAsFixed(1)}%',
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        goal.isCompletedOn(DateTime.now())
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: goal.isCompletedOn(DateTime.now())
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          goal.markAsCompleted(
                            DateTime.now(),
                            !goal.isCompletedOn(DateTime.now()),
                          );
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createExampleGoal,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createExampleGoal() {
    const uuid = Uuid();
    final goal = Goal(
      id: uuid.v4(),
      title: 'Objetivo de ejemplo',
      category: 'General',
      frequency: Frequency.daily,
      createdDate: DateTime.now(),
    );

    DatabaseService.addGoal(goal);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Objetivo creado')),
    );
  }
}
