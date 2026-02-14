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
lifeplan/
├── android/                    # Configuración nativa Android (Gradle, Manifest)
├── ios/                        # Configuración nativa iOS (Xcode)
├── web/                        # Shell HTML para versión web
├── lib/                        # ── Código fuente principal ──
│   ├── main.dart               # Punto de entrada de la aplicación
│   ├── models/
│   │   ├── goal.dart           # Modelo Goal (título, categoría, frecuencia, records)
│   │   ├── goal.g.dart         # TypeAdapter generado para Hive
│   │   ├── frequency.dart      # Enum Frequency (daily, weekly, monthly, yearly)
│   │   └── frequency.g.dart    # TypeAdapter generado para Hive
│   ├── services/
│   │   ├── database_service.dart  # CRUD con Hive (init, add, update, delete)
│   │   └── stats_service.dart     # Cálculos: Life Score, tendencias, rachas, categorías
│   ├── providers/
│   │   └── goal_provider.dart  # Estado global con ChangeNotifier + Provider
│   └── screens/
│       ├── home_screen.dart    # Pantalla principal: lista de objetivos con checkboxes
│       ├── add_goal_screen.dart # Formulario de creación de objetivos
│       └── stats_screen.dart   # Dashboard: gráficos, Life Score, compartir imagen
├── test/                       # Tests unitarios y de widgets
├── pubspec.yaml                # Dependencias y configuración del proyecto
└── README.md
```

## Comandos Útiles
```bash
flutter pub get                                    # Instalar dependencias
flutter pub run build_runner build                # Generar TypeAdapters
flutter analyze                                   # Analizar código
flutter run                                       # Ejecutar app
```
