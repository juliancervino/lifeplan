import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/database_service.dart';
import 'providers/goal_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  // Asegura que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar locale español para el calendario
  await initializeDateFormatting('es');

  // Captura errores globales
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Manejo de errores durante la inicialización
  String? initError;
  try {
    // Inicializa la base de datos Hive
    await DatabaseService.initialize();
    debugPrint('✅ Base de datos inicializada correctamente');
  } catch (e, stackTrace) {
    initError = e.toString();
    debugPrint('❌ Error inicializando base de datos: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  runApp(LifePlanApp(initError: initError));
}

class LifePlanApp extends StatelessWidget {
  final String? initError;
  
  const LifePlanApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    // Si hay error de inicialización, mostrar pantalla de error
    if (initError != null) {
      return MaterialApp(
        title: 'LifePlan - Error',
        home: Scaffold(
          backgroundColor: Colors.red.shade100,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al inicializar la aplicación',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    initError!,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Widget de prueba simple para verificar que Flutter renderiza
    debugPrint('🎨 Construyendo LifePlanApp...');
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            debugPrint('🔧 Creando GoalProvider...');
            return GoalProvider();
          },
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            debugPrint('🔧 Creando SettingsProvider...');
            return SettingsProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'LifePlan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: Builder(
          builder: (context) {
            debugPrint('🏠 Construyendo HomeScreen...');
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
