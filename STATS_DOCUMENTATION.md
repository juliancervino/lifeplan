# 📊 Pantalla de Estadísticas - LifePlan

## Funcionalidades Implementadas

### 1. **Puntuación de Vida (Life Score)** 🏆
- Puntaje del 0 al 100 basado en el promedio de cumplimiento de todos los objetivos
- Cálculo basado en los últimos 30 días
- Colores dinámicos según el puntaje:
  - 🟢 Verde (80-100): Excelente
  - 🟡 Amarillo-Verde (60-79): Bueno
  - 🟠 Naranja (40-59): Medio
  - 🔴 Rojo (0-39): Bajo
- Mensaje motivacional según el puntaje

### 2. **Cálculo de Porcentaje de Cumplimiento** 📈
El sistema calcula automáticamente el porcentaje de cumplimiento basado en:
- **Frecuencia del objetivo**: Diario, Semanal, Mensual, Anual
- **Días esperados en el periodo**: Calcula cuántos días deberían haberse cumplido según la frecuencia
- **Días realmente completados**: Cuenta los días marcados como completados
- **Fórmula**: `(Días Completados / Días Esperados) × 100`

Ejemplos:
- Objetivo Diario: Se espera 1 cumplimiento por día (30 esperados en 30 días)
- Objetivo Semanal: Se espera 1 cumplimiento por semana (~4 esperados en 30 días)
- Objetivo Mensual: Se espera 1 cumplimiento por mes (1 esperado en 30 días)

### 3. **Gráfico de Tendencia de Cumplimiento** 📊
- Gráfico de líneas usando `fl_chart`
- Visualiza el cumplimiento en los últimos N días/semanas
- Opciones de visualización: 7, 14, 30, 60 días
- Para objetivos semanales/mensuales: Agrupa datos por semanas
- Para objetivos diarios: Muestra día por día
- Tooltips interactivos con fecha y porcentaje
- Área sombreada bajo la línea para mejor visualización

### 4. **Estadísticas Detalladas por Objetivo** 📋
Cuando seleccionas un objetivo, muestra:
- **Días activo**: Tiempo desde que se creó el objetivo
- **Completados totales**: Número de veces marcado como completado
- **Últimos 30 días**: Porcentaje de cumplimiento reciente
- **Racha actual**: Días consecutivos cumplidos
- **Mejor racha**: Récord histórico de días consecutivos
- **Cumplimiento total**: Porcentaje de todo el historial

### 5. **Estadísticas por Categoría** 📁
- Agrupa objetivos por categoría
- Muestra el número de objetivos por categoría
- Calcula el cumplimiento promedio de cada categoría
- Barra de progreso visual con colores dinámicos

### 6. **Resumen General** 📋
- Total de objetivos creados
- Objetivos completados hoy
- Objetivos con racha activa

## Estructura de Archivos

```
lib/
├── services/
│   └── stats_service.dart      # Lógica de cálculo de estadísticas
└── screens/
    └── stats_screen.dart       # UI de la pantalla de estadísticas
```

## Uso

### Acceso a Estadísticas
1. Desde HomeScreen, pulsa el ícono 📊 en el AppBar
2. Se abre la pantalla de estadísticas

### Navegación
1. **Ver Puntuación de Vida**: Aparece automáticamente en la parte superior
2. **Ver detalles de un objetivo**: Selecciona en el dropdown
3. **Cambiar periodo del gráfico**: Usa el selector (7d, 14d, 30d, 60d)
4. **Scroll**: Navega por todas las secciones

## Clases y Servicios

### `StatsService`
Servicio estático con métodos para cálculos estadísticos:

#### Métodos Principales:
- `calculateCompletionPercentage(Goal, days)`: Calcula % de cumplimiento
- `getTrendData(Goal, points)`: Genera datos para el gráfico
- `calculateLifeScore(List<Goal>, days)`: Calcula la puntuación de vida
- `getGoalStats(Goal)`: Obtiene estadísticas completas de un objetivo
- `getCategoryStats(List<Goal>)`: Estadísticas agrupadas por categoría

#### Clases de Datos:
- `CompletionDataPoint`: Punto de datos para gráfico (fecha, tasa)
- `GoalStats`: Estadísticas completas de un objetivo
- `CategoryStats`: Estadísticas de una categoría

### `StatsScreen`
Widget con estado que muestra todas las estadísticas:
- Estado: Goal seleccionado, días de tendencia
- Widgets privados para cada sección de UI
- Integración con Provider para datos en tiempo real

## Dependencias Añadidas

```yaml
dependencies:
  fl_chart: ^0.66.0  # Para gráficos de líneas
```

## Ejemplo de Uso del Servicio

```dart
// Calcular porcentaje de cumplimiento de un objetivo
final completion = StatsService.calculateCompletionPercentage(
  goal, 
  days: 30,
);

// Obtener datos para gráfico
final trendData = StatsService.getTrendData(
  goal, 
  points: 30,
);

// Calcular Life Score
final lifeScore = StatsService.calculateLifeScore(
  allGoals, 
  days: 30,
);

// Obtener estadísticas completas
final stats = StatsService.getGoalStats(goal);
```

## Características Técnicas

### Rendimiento
- Cálculos optimizados para grandes volúmenes de datos
- Uso eficiente de memoria con iteraciones únicas
- Caché implícito a través de Provider

### Precisión
- Considera la fecha de creación del objetivo (no cuenta días anteriores)
- Maneja correctamente los límites de periodos
- Redondeo apropiado para frecuencias (ceil para semanas, meses)

### UX/UI
- Colores dinámicos según rendimiento
- Mensajes motivacionales personalizados
- Feedback visual con barras de progreso
- Tooltips informativos en gráficos
- Navegación intuitiva

## Próximas Mejoras Posibles
- [ ] Exportar gráficos como imágenes para compartir
- [ ] Comparación entre periodos
- [ ] Predicciones basadas en tendencias
- [ ] Logros y medallas por hitos alcanzados
- [ ] Vista de calendario mensual
- [ ] Filtros avanzados (por frecuencia, categoría, etc.)
