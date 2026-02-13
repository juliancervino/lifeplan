# 🎯 LifePlan

**App de seguimiento de hábitos y objetivos de vida — 100% offline y privada.**

LifePlan es una aplicación móvil multiplataforma (Android, iOS, Web) construida con Flutter que permite crear, monitorizar y analizar hábitos y metas personales sin necesidad de conexión a internet ni cuentas en la nube. Todos los datos se almacenan localmente en el dispositivo del usuario.

## ✨ Características principales

- **Offline-first** — No requiere internet, backend ni API Keys. Tus datos nunca salen de tu dispositivo.
- **Frecuencias flexibles** — Objetivos diarios, semanales, mensuales y anuales con reset automático por periodo.
- **Sistema Yes/No** — Marca cada hábito como cumplido o pendiente con un solo toque.
- **Dashboard de estadísticas** — Gráficos de tendencia con `fl_chart`, porcentajes de cumplimiento y rachas.
- **Life Score** — Puntuación de vida global (0–100) con desglose por frecuencia.
- **Compartir progreso** — Captura y comparte tu resumen de Life Score como imagen.
- **Persistencia local** — Base de datos Hive con TypeAdapters para almacenamiento rápido y fiable.

---

## 📋 Requisitos previos

Antes de comenzar, asegúrate de tener instalado:

| Software | Versión mínima | Notas |
|---|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.27.x | Incluye Dart 3.6.x |
| [Android Studio](https://developer.android.com/studio) o Android SDK CLI | API 34 | Para compilar APK |
| [Xcode](https://developer.apple.com/xcode/) | 15+ | Solo en macOS, para iOS |
| [VS Code](https://code.visualstudio.com/) | Última versión | Recomendado con extensión Flutter |
| [Java JDK](https://adoptium.net/) | 17 o 21 | Requerido por Gradle |

Verifica que tu entorno esté correctamente configurado:

```bash
flutter doctor
```

Todos los checks de la plataforma objetivo deben aparecer con ✓.

---

## 🚀 Instalación y configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/lifeplan.git
cd lifeplan
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Generar TypeAdapters de Hive

Los modelos de datos (`Goal`, `Frequency`) usan Hive TypeAdapters que requieren generación de código:

```bash
dart run build_runner build --delete-conflicting-outputs
```

> **Nota:** Los archivos generados (`*.g.dart`) ya están incluidos en el repositorio. Solo necesitas ejecutar este comando si modificas los modelos en `lib/models/`.

---

## ▶️ Ejecución en desarrollo

### Emulador o dispositivo físico (Android/iOS)

```bash
flutter run
```

Si tienes múltiples dispositivos conectados, selecciona uno:

```bash
flutter devices          # Listar dispositivos disponibles
flutter run -d <device>  # Ejecutar en un dispositivo específico
```

### Versión Web (Chrome)

```bash
flutter run -d chrome
```

### Modo release (rendimiento real)

```bash
flutter run --release
```

---

## 📦 Compilación y despliegue

### Android — Generar APK

```bash
flutter build apk --release
```

El APK se genera en:

```
build/app/outputs/flutter-apk/app-release.apk
```

Para instalar directamente en un dispositivo conectado por USB:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Android — Generar App Bundle (Google Play)

```bash
flutter build appbundle --release
```

Salida: `build/app/outputs/bundle/release/app-release.aab`

### Web — Build de producción

```bash
flutter build web --release
```

Salida: `build/web/` — Sirve con cualquier servidor HTTP estático.

### iOS (requiere macOS + Xcode)

```bash
flutter build ios --release
```

---

## 🗂️ Estructura del proyecto

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

---

## 🔧 Stack técnico

| Componente | Tecnología | Versión |
|---|---|---|
| Framework | Flutter | 3.27.1 |
| Lenguaje | Dart | 3.6.0 |
| Base de datos local | Hive + hive_flutter | 2.2.3 |
| Estado | Provider | 6.1.1 |
| Gráficos | fl_chart | 0.66.0 |
| Captura de pantalla | screenshot | 3.0.0 |
| Compartir | share_plus | 10.1.2 |
| Generación de código | build_runner + hive_generator | 2.4.7 / 2.0.1 |

---

## 🔒 Privacidad y datos

LifePlan es **100% offline**:

- No se conecta a ningún servidor ni API externa.
- No recopila datos personales ni telemetría.
- Todos los datos se almacenan en el dispositivo usando Hive (IndexedDB en web, archivos locales en móvil).
- No requiere configuración de API Keys ni servicios en la nube.
- No necesita permisos de red.

---

## 🐛 Solución de problemas frecuentes

### Error: Incompatibilidad de Gradle con Java 21

```
Could not resolve all files for configuration ':path_provider_android:androidJdkImage'
Error while executing process jlink...
```

**Causa:** Android Gradle Plugin (AGP) < 8.2.1 no es compatible con Java 21.

**Solución:** Actualiza la versión de AGP en `android/settings.gradle`:

```groovy
plugins {
    id "com.android.application" version "8.2.2" apply false  // Mínimo 8.2.1
    id "org.jetbrains.kotlin.android" version "1.9.22" apply false
}
```

Y asegúrate de usar Gradle 8.7+ en `android/gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-all.zip
```

---

### Error: Licencias de Android SDK no aceptadas

```
Android license status unknown. Run `flutter doctor --android-licenses`
```

**Solución:**

```bash
flutter doctor --android-licenses
```

Acepta todas las licencias escribiendo `y` cuando se te solicite.

---

### Error: Android SDK no encontrado

```
Unable to locate Android SDK
```

**Solución:** Configura la ruta del SDK:

```bash
flutter config --android-sdk /ruta/al/Android/Sdk
```

Rutas habituales:
- **Linux/WSL:** `~/Android/Sdk`
- **macOS:** `~/Library/Android/sdk`
- **Windows:** `%LOCALAPPDATA%\Android\Sdk`

---

### Error: "unsupported Gradle project" (falta directorio android/)

```
Your app is using an unsupported Gradle project setup
```

**Solución:** Regenera los archivos de plataforma:

```bash
flutter create --platforms android .
```

> Esto crea el directorio `android/` sin modificar el código existente en `lib/`.

---

### Error: TypeAdapters desactualizados o faltantes

```
type 'Null' is not a subtype of type 'Goal'
```

**Solución:** Regenera los archivos `*.g.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### flutter doctor muestra componentes faltantes del SDK

Instala los componentes necesarios manualmente:

```bash
sdkmanager --install "platforms;android-34" "build-tools;34.0.0" "platform-tools"
```

---

## 📄 Licencia

Este proyecto es de uso personal. Consulta el archivo `LICENSE` para más detalles.

---

## ℹ️ Acerca de

| | |
|---|---|
| **Nombre** | LifePlan |
| **Versión** | 1.0.0 |
| **Build** | 1 |
| **Paquete** | `com.example.lifeplan` |
