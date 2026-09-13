import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/totp_providers.dart';
import '../data/models/totp_model.dart';

class TotpScreen extends ConsumerStatefulWidget {
  const TotpScreen({super.key});
  @override
  ConsumerState<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends ConsumerState<TotpScreen> {
  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 30;
      setState(() => _secondsRemaining = 30 - elapsed);
      if (_secondsRemaining == 30) {
        ref.read(totpProvider.notifier).generateAllCodes();
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(totpProvider);
    final notifier = ref.read(totpProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Authenticator')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDialog(context, ref), child: const Icon(Icons.add)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.entries.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.security, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No authenticator entries')]))
              : Column(children: [
                  Padding(padding: const EdgeInsets.all(16), child: LinearProgressIndicator(value: _secondsRemaining / 30)),
                  Expanded(child: ListView.builder(itemCount: state.entries.length, itemBuilder: (ctx, i) {
                    final entry = state.entries[i];
                    final code = state.currentCodes[entry.id] ?? '------';
                    return ListTile(
                      leading: CircleAvatar(child: Text(entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?')),
                      title: Text(entry.name),
                      subtitle: Text(entry.issuer.isNotEmpty ? entry.issuer : 'TOTP'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(code, style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => notifier.deleteEntry(entry.id)),
                      ]),
                      onTap: () { Clipboard.setData(ClipboardData(text: code)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied'))); },
                    );
                  })),
                ]),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Authenticator'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. GitHub)')),
        TextField(controller: issuerCtrl, decoration: const InputDecoration(labelText: 'Issuer (optional)')),
        TextField(controller: secretCtrl, decoration: const InputDecoration(labelText: 'Secret Key (base32)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(totpProvider.notifier).createEntry(TotpModel(id: '', name: nameCtrl.text, issuer: issuerCtrl.text, secret: secretCtrl.text));
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }
}
