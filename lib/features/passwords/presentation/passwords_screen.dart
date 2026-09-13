import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/passwords_providers.dart';
import '../data/models/password_model.dart';

class PasswordsScreen extends ConsumerWidget {
  const PasswordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passwordsProvider);
    final notifier = ref.read(passwordsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Passwords')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddEditDialog(context, ref), child: const Icon(Icons.add)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.passwords.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No passwords yet')]))
              : ListView.builder(itemCount: state.passwords.length, itemBuilder: (ctx, i) {
                  final pw = state.passwords[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(pw.siteName.isNotEmpty ? pw.siteName[0].toUpperCase() : '?')),
                    title: Text(pw.siteName),
                    subtitle: Text(pw.username.isNotEmpty ? pw.username : pw.url),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () { Clipboard.setData(ClipboardData(text: pw.encryptedPassword)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied'))); }),
                      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => notifier.deletePassword(pw.id)),
                    ]),
                  );
                }),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, {PasswordModel? existing}) {
    final siteCtrl = TextEditingController(text: existing?.siteName);
    final urlCtrl = TextEditingController(text: existing?.url);
    final userCtrl = TextEditingController(text: existing?.username);
    final passCtrl = TextEditingController(text: existing?.encryptedPassword);
    final notesCtrl = TextEditingController(text: existing?.notes);
    bool obscure = true;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(existing == null ? 'Add Password' : 'Edit Password'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: siteCtrl, decoration: const InputDecoration(labelText: 'Site Name')),
        TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
        TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
        TextField(controller: passCtrl, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setDialogState(() => obscure = !obscure))), obscureText: obscure),
        Row(children: [TextButton(onPressed: () { final generated = _generatePassword(); passCtrl.text = generated; setDialogState(() {}); }, child: const Text('Generate')), const Spacer()]),
        TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final pw = PasswordModel(id: existing?.id ?? '', siteName: siteCtrl.text, url: urlCtrl.text, username: userCtrl.text, encryptedPassword: passCtrl.text, notes: notesCtrl.text);
          if (existing == null) ref.read(passwordsProvider.notifier).createPassword(pw); else ref.read(passwordsProvider.notifier).updatePassword(pw);
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    )));
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
