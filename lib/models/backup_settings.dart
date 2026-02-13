import 'package:hive/hive.dart';

part 'backup_settings.g.dart';

@HiveType(typeId: 2)
class BackupSettings extends HiveObject {
  @HiveField(0)
  bool autoBackupEnabled;

  @HiveField(1)
  int backupHour;

  @HiveField(2)
  int backupMinute;

  @HiveField(3)
  int maxBackupCount;

  @HiveField(4)
  DateTime? lastBackupDate;

  @HiveField(5)
  String? googleEmail;

  BackupSettings({
    this.autoBackupEnabled = false,
    this.backupHour = 2,
    this.backupMinute = 0,
    this.maxBackupCount = 7,
    this.lastBackupDate,
    this.googleEmail,
  });

  /// Hora formateada como HH:mm
  String get backupTimeFormatted =>
      '${backupHour.toString().padLeft(2, '0')}:${backupMinute.toString().padLeft(2, '0')}';

  /// Verifica si hay un backup pendiente hoy
  bool get isBackupPending {
    if (!autoBackupEnabled) return false;
    if (lastBackupDate == null) return true;

    final now = DateTime.now();
    final scheduledToday = DateTime(now.year, now.month, now.day, backupHour, backupMinute);

    // Si ya pasó la hora programada y el último backup fue antes de hoy
    if (now.isAfter(scheduledToday)) {
      final lastBackupDay = DateTime(
        lastBackupDate!.year,
        lastBackupDate!.month,
        lastBackupDate!.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      return lastBackupDay.isBefore(today);
    }

    return false;
  }

  /// Indica si la cuenta de Google está conectada
  bool get isGoogleConnected => googleEmail != null && googleEmail!.isNotEmpty;

  /// Indica si el último backup tiene más de 48 horas
  bool get isBackupStale {
    if (lastBackupDate == null) return false;
    return DateTime.now().difference(lastBackupDate!).inHours > 48;
  }

  BackupSettings copyWith({
    bool? autoBackupEnabled,
    int? backupHour,
    int? backupMinute,
    int? maxBackupCount,
    DateTime? lastBackupDate,
    String? googleEmail,
  }) {
    return BackupSettings(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupHour: backupHour ?? this.backupHour,
      backupMinute: backupMinute ?? this.backupMinute,
      maxBackupCount: maxBackupCount ?? this.maxBackupCount,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      googleEmail: googleEmail ?? this.googleEmail,
    );
  }
}
