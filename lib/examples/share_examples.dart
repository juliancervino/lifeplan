import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Ejemplo de uso del paquete screenshot y share_plus
/// para capturar y compartir widgets de Flutter

void main() {
  runApp(const ShareExampleApp());
}

class ShareExampleApp extends StatelessWidget {
  const ShareExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Chart Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ShareChartExample(),
    );
  }
}

class ShareChartExample extends StatefulWidget {
  const ShareChartExample({super.key});

  @override
  State<ShareChartExample> createState() => _ShareChartExampleState();
}

class _ShareChartExampleState extends State<ShareChartExample> {
  // 1. Crear el ScreenshotController
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo de Compartir'),
        actions: [
          // 2. Botón de compartir en el AppBar
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
            onPressed: _isSharing ? null : _shareWidget,
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3. Envolver el widget a capturar con Screenshot
              Screenshot(
                controller: _screenshotController,
                child: _buildSharableWidget(),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareWidget,
                icon: const Icon(Icons.share),
                label: const Text('Compartir Widget'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget que se va a capturar y compartir
  Widget _buildSharableWidget() {
    return Card(
      color: Colors.white, // Fondo blanco para mejor captura
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              '¡Mi Progreso!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '85% de cumplimiento',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.85,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Método para capturar y compartir el widget
  Future<void> _shareWidget() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Paso 1: Capturar el widget como imagen
      final image = await _screenshotController.capture();

      if (image == null) {
        throw Exception('No se pudo capturar la imagen');
      }

      // Paso 2: Guardar la imagen en un archivo temporal
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/my_progress_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      // Paso 3: Crear el mensaje para compartir
      final message = '''🌟 ¡Mira mi progreso!

Este es un ejemplo de cómo compartir un widget de Flutter como imagen.

📊 Progreso: 85%
📅 Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

¡Sígueme en mi camino!''';

      // Paso 4: Compartir usando el diálogo nativo del sistema
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: message,
        subject: 'Mi Progreso',
      );

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Compartido exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Manejo de errores
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}

// ============================================
// EJEMPLO 2: Compartir un gráfico personalizado
// ============================================

class CustomChartShareExample extends StatefulWidget {
  const CustomChartShareExample({super.key});

  @override
  State<CustomChartShareExample> createState() => _CustomChartShareExampleState();
}

class _CustomChartShareExampleState extends State<CustomChartShareExample> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir Gráfico')),
      body: Center(
        child: Screenshot(
          controller: _screenshotController,
          child: _buildCustomChart(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _shareChart('Mi Gráfico Personalizado', 75.0),
        child: const Icon(Icons.share),
      ),
    );
  }

  Widget _buildCustomChart() {
    return Card(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mi Gráfico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Aquí iría tu gráfico personalizado (fl_chart, etc.)
            Container(
              height: 200,
              color: Colors.blue[100],
              child: const Center(child: Text('Gráfico aquí')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareChart(String chartName, double value) async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) throw Exception('Captura falló');

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(imagePath).writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: '📊 $chartName\n📈 Valor: ${value.toStringAsFixed(0)}%',
      );
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}

// ============================================
// EJEMPLO 3: Compartir solo texto (sin imagen)
// ============================================

class TextShareExample extends StatelessWidget {
  const TextShareExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir Texto')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _shareText(),
          child: const Text('Compartir Texto'),
        ),
      ),
    );
  }

  Future<void> _shareText() async {
    await Share.share(
      '¡Hola! Este es un mensaje compartido desde Flutter usando share_plus.',
      subject: 'Mi mensaje',
    );
  }
}

// ============================================
// EJEMPLO 4: Compartir múltiples archivos
// ============================================

class MultiFileShareExample extends StatelessWidget {
  const MultiFileShareExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir Múltiples Archivos')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _shareMultipleFiles(),
          child: const Text('Compartir Varios'),
        ),
      ),
    );
  }

  Future<void> _shareMultipleFiles() async {
    // Crear múltiples archivos temporales
    final directory = await getTemporaryDirectory();
    
    final file1 = File('${directory.path}/file1.txt');
    await file1.writeAsString('Contenido del archivo 1');
    
    final file2 = File('${directory.path}/file2.txt');
    await file2.writeAsString('Contenido del archivo 2');

    // Compartir múltiples archivos
    await Share.shareXFiles(
      [XFile(file1.path), XFile(file2.path)],
      text: 'Compartiendo múltiples archivos',
    );
  }
}

// ============================================
// NOTAS IMPORTANTES
// ============================================

/*
1. CAPTURA DE WIDGETS:
   - Screenshot captura el widget exactamente como se ve en pantalla
   - Usa color de fondo blanco para mejores capturas
   - El widget debe estar montado (visible) para capturarse

2. ARCHIVOS TEMPORALES:
   - Usa getTemporaryDirectory() para archivos temporales
   - El sistema limpia estos archivos automáticamente
   - No es necesario eliminarlos manualmente

3. PLATAFORMAS:
   - Android/iOS: Diálogo nativo completo
   - Web: Descarga el archivo
   - Desktop: Funcionalidad limitada según SO

4. MANEJO DE ERRORES:
   - Siempre usa try-catch
   - Verifica que capture() no retorne null
   - Muestra feedback al usuario con SnackBar

5. ESTADO DE CARGA:
   - Usa una variable bool para mostrar loading
   - Desactiva el botón mientras se comparte
   - Siempre limpia el estado en finally

6. PERMISOS:
   - Android: No requiere permisos especiales para share_plus
   - iOS: No requiere configuración adicional
   - Screenshot: No requiere permisos

7. MEJORES PRÁCTICAS:
   - Siempre verifica mounted antes de setState
   - Usa async/await para operaciones asíncronas
   - Proporciona mensajes informativos al compartir
   - Incluye subject para mejor experiencia
*/
