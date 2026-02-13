# LifePlan Flutter App

## Project Overview
Cross-platform mobile app (iOS & Android) for habit and goal tracking with offline-first architecture.

## Tech Stack
- Flutter 3.27.1 / Dart 3.6.0
- Hive 2.2.3 (local database with TypeAdapters)
- Provider 6.1.5 (state management)
- Offline-first (no backend/internet required)

## Key Features
- Create and monitor habits/goals
- Multiple frequencies: daily, weekly, monthly, yearly
- Yes/No tracking system
- Dashboard with trends, completion percentages, and scoring
- Export progress charts as images for sharing

## Data Model
- Goal: id, title, category, frequency (enum), createdDate, records (completion dates)

## Development Status
✅ Flutter SDK instalado (3.27.1)
✅ Proyecto configurado con dependencias
✅ Modelos de datos con TypeAdapters generados
✅ DatabaseService implementado
✅ GoalProvider para gestión de estado
✅ UI completa: HomeScreen y AddGoalScreen
✅ Código sin errores (flutter analyze passed)

## Estructura del Proyecto
```
lib/
├── models/
│   ├── frequency.dart        # Enum de frecuencias con TypeAdapter
│   ├── frequency.g.dart      # TypeAdapter generado
│   ├── goal.dart            # Modelo principal con métodos
│   └── goal.g.dart          # TypeAdapter generado
├── services/
│   └── database_service.dart # Servicio de base de datos Hive
├── providers/
│   └── goal_provider.dart   # Gestión de estado con Provider
├── screens/
│   ├── home_screen.dart     # Pantalla principal con lista
│   └── add_goal_screen.dart # Formulario para crear objetivos
├── database_example.dart     # Ejemplos de uso
└── main.dart                # Punto de entrada
```

## Comandos Útiles
```bash
flutter pub get                                    # Instalar dependencias
flutter pub run build_runner build                # Generar TypeAdapters
flutter analyze                                   # Analizar código
flutter run                                       # Ejecutar app
```
