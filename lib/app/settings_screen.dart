import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _load2FaStatus();
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
        ListTile(leading: const Icon(Icons.lock), title: const Text('Change Password'), onTap: _changePassword),
        ListTile(leading: const Icon(Icons.security), title: const Text('Two-Factor Auth'), subtitle: Text(_twoFaEnabled ? 'Enabled' : 'Disabled'),
          trailing: Switch(value: _twoFaEnabled, onChanged: (_) => _toggle2FA())),
        ListTile(leading: const Icon(Icons.devices), title: const Text('Active Sessions'),
          trailing: _loadingSessions ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
          onTap: () { _loadSessions(); _showSessionsDialog(); }),
        const Divider(),
        // Appearance
        ListTile(leading: const Icon(Icons.palette), title: const Text('Theme'), subtitle: const Text('System default'),
          trailing: const Icon(Icons.chevron_right), onTap: _showThemeDialog),
        // Navigation to other features
        const Divider(),
        ListTile(leading: const Icon(Icons.history), title: const Text('Activity Log'), onTap: () => context.push('/activity')),
        ListTile(leading: const Icon(Icons.label_outline), title: const Text('Tags'), onTap: () => context.push('/tags')),
        ListTile(leading: const Icon(Icons.hub_outlined), title: const Text('Knowledge Graph'), onTap: () => context.push('/graph')),
        ListTile(leading: const Icon(Icons.videocam), title: const Text('Videos'), onTap: () => context.push('/videos')),
        const Divider(),
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
        SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text('System default')),
        SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text('Light')),
        SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text('Dark')),
      ],
    ));
  }
}
