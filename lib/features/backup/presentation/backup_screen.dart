import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _message;

  Future<void> _exportBackup() async {
    setState(() { _isExporting = true; _message = null; });
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.dio.post(Endpoints.exportBackup);
      setState(() { _isExporting = false; _message = 'Backup exported successfully'; });
    } catch (e) {
      setState(() { _isExporting = false; _message = 'Export failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 32),
        Icon(Icons.cloud_upload, size: 80, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text('Backup your data', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Export all your data to the server for safekeeping. This includes notes, todos, projects, and all other content.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton.icon(onPressed: _isExporting ? null : _exportBackup, icon: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload), label: Text(_isExporting ? 'Exporting...' : 'Export Backup')),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import feature coming soon'))); }, icon: const Icon(Icons.cloud_download), label: const Text('Import from Backup')),
        if (_message != null) ...[const SizedBox(height: 16), Text(_message!, style: theme.textTheme.bodyMedium?.copyWith(color: _message!.contains('failed') ? Colors.red : Colors.green), textAlign: TextAlign.center)],
        const Spacer(),
        Text('Note: Client-only data (Mail, Voice, Finance) is stored locally and not included in server backups.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
      ])),
    );
  }
}
