/// Utilidades compartidas para operaciones con fechas.
///
/// Centraliza la lógica de normalización y formateo de fechas
/// que se repite en goal.dart, stats_service.dart y home_screen.dart.
class AppDateUtils {
  AppDateUtils._();

  /// Normaliza una fecha a medianoche (00:00:00), eliminando la hora.
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Formatea una fecha como 'YYYY-MM-DD' para usarla como clave en records.
  static String formatKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clave de semana basada en el lunes de esa semana ('YYYY-MM-DD').
  static String weekKey(DateTime d) {
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  /// Clave de mes ('YYYY-MM').
  static String monthKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  /// Clave de año ('YYYY').
  static String yearKey(DateTime d) => '${d.year}';
}
