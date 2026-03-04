import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../providers/goal_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGoogleAccountSection(context, settingsProvider),
                  if (settingsProvider.isGoogleConnected) ...[
                    const SizedBox(height: 24),
                    _buildAutoBackupSection(context, settingsProvider),
                    const SizedBox(height: 24),
                    _buildManualBackupSection(context, settingsProvider),
                    const SizedBox(height: 24),
                    _buildRestoreSection(context, settingsProvider),
                  ],
                ],
              ),
              // Overlay de progreso durante backup/restauración
              if (settingsProvider.isBackingUp || settingsProvider.isRestoring)
                _buildProgressOverlay(settingsProvider),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Sección: Cuenta de Google
  // ──────────────────────────────────────────────
  Widget _buildGoogleAccountSection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  provider.isGoogleConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: provider.isGoogleConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cuenta de Google',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isGoogleConnected) ...[
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.googleEmail ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Conectada',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDisconnectDialog(context, provider),
                  icon: const Icon(Icons.link_off, color: Colors.red),
                  label: const Text('Desconectar cuenta', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            ] else ...[
              const Text(
                'Conecta tu cuenta de Google para habilitar los backups en Google Drive.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => provider.signInWithGoogle(),
                  icon: const Icon(Icons.login),
                  label: const Text('Conectar con Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Sección: Backup Automático
  // ──────────────────────────────────────────────
  Widget _buildAutoBackupSection(BuildContext context, SettingsProvider provider) {
    final settings = provider.settings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  'Backup Automático',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: settings.autoBackupEnabled,
              onChanged: (value) => provider.setAutoBackupEnabled(value),
              title: const Text('Activar backup diario'),
              subtitle: const Text('Se comprobará cada vez que abras la app'),
              contentPadding: EdgeInsets.zero,
            ),
            if (settings.autoBackupEnabled) ...[
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Máximo de copias'),
                subtitle: Text('Se mantendrán las ${settings.maxBackupCount} más recientes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: settings.maxBackupCount > 1
                          ? () => provider.setMaxBackupCount(settings.maxBackupCount - 1)
                          : null,
                    ),
                    Text(
                      '${settings.maxBackupCount}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: settings.maxBackupCount < 30
                          ? () => provider.setMaxBackupCount(settings.maxBackupCount + 1)
                          : null,
                    ),
                  ],
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 8),
            _buildLastBackupInfo(settings.lastBackupDate),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Sección: Backup Manual
  // ──────────────────────────────────────────────
  Widget _buildManualBackupSection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  'Backup Manual',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Crea una copia de seguridad ahora en Google Drive.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isBackingUp
                    ? null
                    : () => _performManualBackup(context, provider),
                icon: provider.isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                label: Text(provider.isBackingUp ? 'Creando backup...' : 'Hacer backup ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Sección: Restaurar Backup
  // ──────────────────────────────────────────────
  Widget _buildRestoreSection(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restore, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  'Restaurar Backup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Restaura tus datos desde una copia de seguridad en Google Drive.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isRestoring
                    ? null
                    : () => _showBackupListDialog(context, provider),
                icon: const Icon(Icons.cloud_download),
                label: const Text('Restaurar desde Google Drive'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Helpers de UI
  // ──────────────────────────────────────────────
  Widget _buildLastBackupInfo(DateTime? lastBackup) {
    if (lastBackup == null) {
      return Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text(
            'Nunca se ha realizado un backup',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
          ),
        ],
      );
    }

    final formatted = DateFormat('dd/MM/yyyy HH:mm').format(lastBackup);
    final isStale = DateTime.now().difference(lastBackup).inHours > 48;

    return Row(
      children: [
        Icon(
          isStale ? Icons.warning_amber : Icons.check_circle,
          size: 16,
          color: isStale ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Último backup: $formatted',
            style: TextStyle(
              fontSize: 12,
              color: isStale ? Colors.orange.shade700 : Colors.green.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressOverlay(SettingsProvider provider) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  provider.isBackingUp
                      ? 'Creando backup...'
                      : 'Restaurando datos...',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.isBackingUp
                      ? 'Subiendo datos a Google Drive'
                      : 'Descargando y aplicando backup',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Acciones
  // ──────────────────────────────────────────────
  Future<void> _performManualBackup(BuildContext context, SettingsProvider provider) async {
    final success = await provider.performBackup();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Backup creado correctamente'
              : '❌ Error al crear el backup',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _showDisconnectDialog(BuildContext context, SettingsProvider provider) async {
    bool deleteBackups = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Desconectar cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Quieres desconectar tu cuenta de Google?'),
              const SizedBox(height: 12),
              const Text(
                'Se desactivará el backup automático.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: deleteBackups,
                onChanged: (v) => setState(() => deleteBackups = v ?? false),
                title: const Text('Eliminar backups en Drive', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Se borrarán todas las copias', style: TextStyle(fontSize: 12)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desconectar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await provider.signOutGoogle(deleteRemoteBackups: deleteBackups);
    }
  }

  Future<void> _showBackupListDialog(BuildContext context, SettingsProvider provider) async {
    // Cargar lista de backups
    await provider.loadBackups();

    if (!context.mounted) return;

    if (provider.backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay backups disponibles en Google Drive')),
      );
      return;
    }

    final selectedId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.backups.length,
            itemBuilder: (context, index) {
              final backup = provider.backups[index];
              return ListTile(
                leading: const Icon(Icons.cloud_download),
                title: Text(backup.dateFormatted),
                subtitle: Text(backup.sizeFormatted),
                trailing: index == 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Más reciente',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      )
                    : null,
                onTap: () => Navigator.pop(context, backup.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedId != null && context.mounted) {
      await _confirmRestore(context, provider, selectedId);
    }
  }

  Future<void> _confirmRestore(
    BuildContext context,
    SettingsProvider provider,
    String fileId,
  ) async {
    bool createSafetyBackup = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('¿Restaurar backup?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Se reemplazarán todos los datos actuales. Esta acción no se puede deshacer.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: createSafetyBackup,
                onChanged: (v) => setState(() => createSafetyBackup = v ?? true),
                title: const Text(
                  'Crear backup de seguridad antes de restaurar',
                  style: TextStyle(fontSize: 13),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.restoreBackup(
        fileId,
        createSafetyBackup: createSafetyBackup,
      );

      if (context.mounted) {
        if (success) {
          // Recargar GoalProvider
          context.read<GoalProvider>().loadGoals();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Backup restaurado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${provider.errorMessage ?? "Error al restaurar"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
