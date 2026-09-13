import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/contacts_providers.dart';
import '../data/models/contact_model.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactsProvider);
    final notifier = ref.read(contactsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(icon: const Icon(Icons.file_upload), tooltip: 'Import', onPressed: () => _showImportDialog(context, ref)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDialog(context, ref), child: const Icon(Icons.add)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.contacts.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.contacts, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No contacts yet')]))
              : ListView.builder(itemCount: state.contacts.length, itemBuilder: (ctx, i) {
                  final c = state.contacts[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?')),
                    title: Text(c.displayName),
                    subtitle: Text([c.email, c.phone].where((s) => s.isNotEmpty).join(' · ')),
                    trailing: IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => notifier.deleteContact(c.id)),
                    onTap: () => context.push('/contacts/${c.id}/messages'),
                  );
                }),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Contact'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'First Name')),
        TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
        TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(contactsProvider.notifier).createContact(ContactModel(id: '', firstName: firstCtrl.text, lastName: lastCtrl.text, email: emailCtrl.text, phone: phoneCtrl.text, company: companyCtrl.text));
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Import Contacts'),
      content: TextField(
        controller: ctrl,
        maxLines: 8,
        decoration: const InputDecoration(hintText: 'Paste JSON contacts data...', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (ctrl.text.trim().isNotEmpty) {
            ref.read(contactsProvider.notifier).importContacts(ctrl.text.trim());
            Navigator.pop(ctx);
          }
        }, child: const Text('Import')),
      ],
    ));
  }
}
