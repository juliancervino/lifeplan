import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/frequency.dart';
import '../providers/goal_provider.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  Frequency _selectedFrequency = Frequency.daily;
  bool _isLoading = false;

  final List<String> _suggestedCategories = [
    'Salud',
    'Ejercicio',
    'Trabajo',
    'Estudio',
    'Social',
    'Finanzas',
    'Hogar',
    'Personal',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const uuid = Uuid();
      final newGoal = Goal(
        id: uuid.v4(),
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        frequency: _selectedFrequency,
        createdDate: DateTime.now(),
      );

      final goalProvider = context.read<GoalProvider>();
      await goalProvider.addGoal(newGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Objetivo creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear objetivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Objetivo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Icono y título
            const Icon(
              Icons.flag,
              size: 64,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            const Text(
              'Crea un nuevo hábito u objetivo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Campo de título
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nombre del objetivo *',
                hintText: 'Ej: Hacer ejercicio, Leer 30 minutos',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Campo de categoría con autocompletado
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _suggestedCategories;
                }
                return _suggestedCategories.where((String option) {
                  return option
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _categoryController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _categoryController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    hintText: 'Ej: Salud, Trabajo, Personal',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa una categoría';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Selector de frecuencia
            DropdownButtonFormField<Frequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frecuencia *',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              items: Frequency.values.map((frequency) {
                IconData icon;
                switch (frequency) {
                  case Frequency.daily:
                    icon = Icons.today;
                    break;
                  case Frequency.weekly:
                    icon = Icons.view_week;
                    break;
                  case Frequency.monthly:
                    icon = Icons.calendar_month;
                    break;
                  case Frequency.yearly:
                    icon = Icons.calendar_view_month;
                    break;
                }

                return DropdownMenuItem(
                  value: frequency,
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(frequency.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFrequency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Botón de guardar
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveGoal,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Crear Objetivo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Botón de cancelar
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
