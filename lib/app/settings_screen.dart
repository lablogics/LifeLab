import '../features/push/data/push_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionModel {
  final String id; final String? userAgent; final bool isCurrent; final int? expiresAt;
  const SessionModel({required this.id, this.userAgent, this.isCurrent = false, this.expiresAt});
  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    id: json['id'] as String, userAgent: json['userAgent'] as String?,
    isCurrent: json['isCurrent'] as bool? ?? false, expiresAt: json['expiresAt'] as int?);
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<SessionModel> _sessions = [];
  bool _loadingSessions = false;
  bool _twoFaEnabled = false;
  bool _biometricEnabled = false;
  final _localAuth = LocalAuthentication();
  String _language = 'English';
  String _themeMode = 'system';
  List<Map<String, dynamic>> _storages = [];
  final _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _load2FaStatus();
    _checkBiometric();
    _loadStorages();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final mode = await _secureStorage.read(key: 'themeMode');
      if (mode != null && mounted) setState(() => _themeMode = mode);
    } catch (_) {}
  }

  Future<void> _saveThemeMode(String mode) async {
    setState(() => _themeMode = mode);
    try { await _secureStorage.write(key: 'themeMode', value: mode); } catch (_) {}
  }

  Future<void> _checkBiometric() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final deviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) setState(() => _biometricEnabled = available && deviceSupported);
    } catch (_) {}
  }

  Future<void> _toggleBiometric() async {
    if (_biometricEnabled) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Unlock LifeLab',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (mounted) setState(() => _biometricEnabled = authenticated);
      } catch (_) {}
    }
  }

  Future<void> _load2FaStatus() async {
    try {
      final r = await ref.read(apiClientProvider).dio.dio.get(Endpoints.twoFaStatus);
      if (mounted) setState(() => _twoFaEnabled = r.data['enabled'] as bool? ?? false);
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final r = await ref.read(apiClientProvider).dio.dio.get(Endpoints.sessions);
      final list = (r.data as List? ?? []).map((e) => SessionModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _sessions = list; _loadingSessions = false; });
    } catch (_) { if (mounted) setState(() => _loadingSessions = false); }
  }

  Future<void> _loadStorages() async {
    try {
      final r = await ref.read(apiClientProvider).dio.dio.get(Endpoints.storages);
      final list = (r.data as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _storages = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const SizedBox(height: 16),
        CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 16),
        Center(child: Text(auth.name ?? 'User', style: theme.textTheme.titleLarge)),
        Center(child: Text(auth.email ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))),
        const SizedBox(height: 8),
        Center(child: FilledButton.tonal(onPressed: _editProfile, child: const Text('Edit Profile'))),
        const SizedBox(height: 32),
        const Divider(),
        // Security section
        ListTile(leading: const Icon(Icons.fingerprint), title: const Text('Biometric Unlock'), subtitle: Text(_biometricEnabled ? 'Enabled' : 'Not available'), trailing: Switch(value: _biometricEnabled, onChanged: (_) => _toggleBiometric())),
        ListTile(leading: const Icon(Icons.lock), title: const Text('Change Password'), onTap: _changePassword),
        ListTile(leading: const Icon(Icons.security), title: const Text('Two-Factor Auth'), subtitle: Text(_twoFaEnabled ? 'Enabled' : 'Disabled'),
          trailing: Switch(value: _twoFaEnabled, onChanged: (_) => _toggle2FA())),
        ListTile(leading: const Icon(Icons.devices), title: const Text('Active Sessions'),
          trailing: _loadingSessions ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
          onTap: () { _loadSessions(); _showSessionsDialog(); }),
        const Divider(),
        // Appearance
        ListTile(leading: const Icon(Icons.palette), title: const Text('Theme'), subtitle: Text(_themeMode == 'light' ? 'Light' : _themeMode == 'dark' ? 'Dark' : 'System default'),
          trailing: const Icon(Icons.chevron_right), onTap: _showThemeDialog),
        // Language
        ListTile(leading: const Icon(Icons.language), title: const Text('Language'), subtitle: Text(_language),
          trailing: const Icon(Icons.chevron_right), onTap: _showLanguageDialog),
        const Divider(),
        // Data section
        ListTile(leading: const Icon(Icons.download), title: const Text('Backup & Restore'), subtitle: const Text('Export or import your data'),
          trailing: const Icon(Icons.chevron_right), onTap: _showBackupRestore),
        // Storage backends
        ListTile(leading: const Icon(Icons.storage), title: const Text('Storage Backends'), subtitle: Text('${_storages.length} configured'),
          trailing: const Icon(Icons.chevron_right), onTap: _showStorageBackends),
        const Divider(),
        // Navigation to other features
        ListTile(leading: const Icon(Icons.history), title: const Text('Activity Log'), onTap: () => context.push('/activity')),
        ListTile(leading: const Icon(Icons.label_outline), title: const Text('Tags'), onTap: () => context.push('/tags')),
        ListTile(leading: const Icon(Icons.hub_outlined), title: const Text('Knowledge Graph'), onTap: () => context.push('/graph')),
        ListTile(leading: const Icon(Icons.videocam), title: const Text('Videos'), onTap: () => context.push('/videos')),
        const Divider(),
        ListTile(leading: const Icon(Icons.notifications), title: const Text('Notification Preferences'), onTap: () {
          final push = ref.read(pushProvider.notifier);
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Notifications'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              SwitchListTile(title: const Text('Foreground notifications'), value: ref.read(pushProvider).foregroundEnabled, onChanged: (v) { push.setForegroundEnabled(v); setState(() {}); }),
              SwitchListTile(title: const Text('Background notifications'), value: ref.read(pushProvider).backgroundEnabled, onChanged: (v) { push.setBackgroundEnabled(v); setState(() {}); }),
            ]),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
          ));
        }),
        ListTile(leading: const Icon(Icons.info), title: const Text('About LifeLab'), subtitle: const Text('Version 1.0.0')),
        const Divider(),
        Padding(padding: const EdgeInsets.all(16), child: FilledButton.tonal(onPressed: () async { await ref.read(authProvider.notifier).logout(); if (context.mounted) context.go('/login'); }, child: const Text('Sign Out'))),
      ]),
    );
  }

  void _editProfile() {
    final auth = ref.read(authProvider);
    final nameCtrl = TextEditingController(text: auth.name ?? '');
    final emailCtrl = TextEditingController(text: auth.email ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            await ref.read(apiClientProvider).dio.dio.patch(Endpoints.profile, data: {'name': nameCtrl.text, 'email': emailCtrl.text});
            if (context.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'))); }
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
          }
        }, child: const Text('Save')),
      ],
    ));
  }

  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Change Password'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: currentCtrl, decoration: const InputDecoration(labelText: 'Current password'), obscureText: true),
        const SizedBox(height: 12),
        TextField(controller: newCtrl, decoration: const InputDecoration(labelText: 'New password'), obscureText: true),
        const SizedBox(height: 12),
        TextField(controller: confirmCtrl, decoration: const InputDecoration(labelText: 'Confirm new password'), obscureText: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (newCtrl.text != confirmCtrl.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'))); return; }
          try {
            await ref.read(apiClientProvider).dio.dio.post(Endpoints.changePassword, data: {'currentPassword': currentCtrl.text, 'newPassword': newCtrl.text});
            if (context.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed'))); }
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
          }
        }, child: const Text('Change')),
      ],
    ));
  }

  void _toggle2FA() async {
    if (_twoFaEnabled) {
      final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Disable 2FA'), content: const Text('Are you sure?'), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disable')),
        ]));
      if (confirm != true) return;
      try { await ref.read(apiClientProvider).dio.dio.post(Endpoints.twoFaDisable); } catch (_) {}
    } else {
      try {
        final r = await ref.read(apiClientProvider).dio.dio.post(Endpoints.twoFaEnable);
        final secret = r.data['secret'] as String? ?? '';
        final codes = (r.data['backupCodes'] as List? ?? []).cast<String>();
        if (!mounted) return;
        final verified = await showDialog<bool>(context: context, builder: (ctx) {
          final codeCtrl = TextEditingController();
          return AlertDialog(
            title: const Text('Enable 2FA'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              SelectableText('Secret: $secret', style: const TextStyle(fontFamily: 'monospace')),
              const SizedBox(height: 8),
              if (codes.isNotEmpty) SelectableText('Backup codes:\n${codes.join('\n')}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Verify code'), keyboardType: TextInputType.number),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () async {
                try {
                  await ref.read(apiClientProvider).dio.dio.post(Endpoints.twoFaVerify, data: {'code': codeCtrl.text});
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (_) {}
              }, child: const Text('Verify')),
            ],
          );
        });
        if (verified != true) return;
      } catch (_) {}
    }
    _load2FaStatus();
    _checkBiometric();
  }

  void _showSessionsDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Active Sessions'),
      content: SizedBox(width: 400, height: 300, child: _loadingSessions
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('No sessions'))
              : ListView.builder(itemCount: _sessions.length, itemBuilder: (_, i) {
                  final s = _sessions[i];
                  final exp = s.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(s.expiresAt!) : null;
                  return ListTile(
                    title: Text(s.userAgent ?? 'Unknown device', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: exp != null ? Text('Expires: ${exp.toLocal()}') : null,
                    trailing: s.isCurrent ? const Chip(label: Text('Current')) : IconButton(icon: const Icon(Icons.logout), onPressed: () async {
                      await ref.read(apiClientProvider).dio.dio.delete('${Endpoints.sessions}/${s.id}');
                      _loadSessions();
                    }),
                  );
                })),
      actions: [
        if (_sessions.where((s) => !s.isCurrent).isNotEmpty)
          TextButton(onPressed: () async {
            await ref.read(apiClientProvider).dio.dio.delete(Endpoints.sessions);
            _loadSessions();
          }, child: const Text('Revoke All')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ));
  }

  void _showThemeDialog() {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Theme'),
      children: [
        SimpleDialogOption(onPressed: () { _saveThemeMode('system'); Navigator.pop(ctx); },
          child: Row(children: [if (_themeMode == 'system') const Icon(Icons.check, size: 16), const SizedBox(width: 8), const Text('System default')])),
        SimpleDialogOption(onPressed: () { _saveThemeMode('light'); Navigator.pop(ctx); },
          child: Row(children: [if (_themeMode == 'light') const Icon(Icons.check, size: 16), const SizedBox(width: 8), const Text('Light')])),
        SimpleDialogOption(onPressed: () { _saveThemeMode('dark'); Navigator.pop(ctx); },
          child: Row(children: [if (_themeMode == 'dark') const Icon(Icons.check, size: 16), const SizedBox(width: 8), const Text('Dark')])),
      ],
    ));
  }

  void _showLanguageDialog() {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Language'),
      children: [
        SimpleDialogOption(onPressed: () { setState(() => _language = 'English'); Navigator.pop(ctx); }, child: const Text('English')),
        SimpleDialogOption(onPressed: () { setState(() => _language = 'Fran\u00e7ais'); Navigator.pop(ctx); }, child: const Text('Fran\u00e7ais')),
        SimpleDialogOption(onPressed: () { setState(() => _language = '\u0627\u0644\u0639\u0631\u0628\u064a\u0629'); Navigator.pop(ctx); }, child: const Text('\u0627\u0644\u0639\u0631\u0628\u064a\u0629')),
        SimpleDialogOption(onPressed: () { setState(() => _language = 'Darija'); Navigator.pop(ctx); }, child: const Text('Darija')),
      ],
    ));
  }

  void _showBackupRestore() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Backup & Restore'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Export all your data as a JSON backup file, or restore from a previous backup.'),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.download), title: const Text('Full Backup'), onTap: () async {
          Navigator.pop(ctx);
          try {
            final api = ref.read(apiClientProvider);
            await api.dio.dio.get(Endpoints.exportBackup, options: Options(responseType: ResponseType.bytes));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup exported')));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
          }
        }),
        ListTile(leading: const Icon(Icons.upload), title: const Text('Restore from Backup'), onTap: () async {
          Navigator.pop(ctx);
          try {
            final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
            if (result == null || result.files.isEmpty) return;
            final file = result.files.first;
            final content = await file.xFile.readAsString();
            final api = ref.read(apiClientProvider);
            await api.dio.dio.post(Endpoints.exportImport, data: jsonDecode(content));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data restored successfully')));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
          }
        }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }

  void _showStorageBackends() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Storage Backends'),
      content: SizedBox(
        width: 400, height: 400,
        child: Column(children: [
          Expanded(child: _storages.isEmpty
              ? const Center(child: Text('No storage backends configured'))
              : ListView.builder(itemCount: _storages.length, itemBuilder: (_, i) {
                  final s = _storages[i];
                  return Card(child: ListTile(
                    leading: const Icon(Icons.storage),
                    title: Text(s['name'] as String? ?? 'Storage'),
                    subtitle: Text('${s['storageType'] ?? ''} - ${s['bucket'] ?? ''}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (s['isDefault'] == true) const Chip(label: Text('Default')),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                        try {
                          await ref.read(apiClientProvider).dio.dio.delete('${Endpoints.storages}/${s['id']}');
                          _loadStorages();
                        } catch (_) {}
                      }),
                    ]),
                  ));
                })),
          FilledButton.icon(
            icon: const Icon(Icons.add), label: const Text('Add Storage'),
            onPressed: () { Navigator.pop(ctx); _showAddStorage(); },
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }

  void _showAddStorage() {
    final nameCtrl = TextEditingController();
    final endpointCtrl = TextEditingController();
    final bucketCtrl = TextEditingController();
    final regionCtrl = TextEditingController();
    final accessKeyCtrl = TextEditingController();
    final secretKeyCtrl = TextEditingController();
    String type = 'photos';

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Storage Backend'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display Name')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Type'),
            items: const [DropdownMenuItem(value: 'photos', child: Text('Photos')), DropdownMenuItem(value: 'videos', child: Text('Videos')), DropdownMenuItem(value: 'drives', child: Text('Drive Files'))],
            onChanged: (v) { if (v != null) type = v; }),
          const SizedBox(height: 8),
          TextField(controller: endpointCtrl, decoration: const InputDecoration(labelText: 'S3 Endpoint')),
          const SizedBox(height: 8),
          TextField(controller: regionCtrl, decoration: const InputDecoration(labelText: 'Region')),
          const SizedBox(height: 8),
          TextField(controller: bucketCtrl, decoration: const InputDecoration(labelText: 'Bucket Name')),
          const SizedBox(height: 8),
          TextField(controller: accessKeyCtrl, decoration: const InputDecoration(labelText: 'Access Key')),
          const SizedBox(height: 8),
          TextField(controller: secretKeyCtrl, decoration: const InputDecoration(labelText: 'Secret Key'), obscureText: true),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            final api = ref.read(apiClientProvider);
            await api.dio.dio.post(Endpoints.storages, data: {
              'name': nameCtrl.text, 'storageType': type, 'endpoint': endpointCtrl.text,
              'region': regionCtrl.text, 'bucket': bucketCtrl.text,
              'accessKey': accessKeyCtrl.text, 'secretKey': secretKeyCtrl.text,
            });
            Navigator.pop(ctx);
            _loadStorages();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage added')));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
          }
        }, child: const Text('Add')),
      ],
    ));
  }
}
