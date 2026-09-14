import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../data/contacts_providers.dart';
import '../data/models/contact_model.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});
  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsProvider);
    final theme = Theme.of(context);
    final contacts = state.filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(state.showFavoritesOnly ? Icons.favorite : Icons.favorite_border),
            tooltip: 'Favorites',
            onPressed: () => ref.read(contactsProvider.notifier).toggleFavoritesOnly(),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import CSV/JSON',
            onPressed: () => _importFromFile(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: ref.read(contactsProvider.notifier).setSearch,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.contacts, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(state.searchQuery.isNotEmpty ? 'No contacts match your search' : 'No contacts yet',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
                ]))
              : _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8),
                      itemCount: contacts.length,
                      itemBuilder: (ctx, i) => _ContactGridCard(
                        contact: contacts[i],
                        onTap: () => _showContactDetail(context, contacts[i]),
                        onFavorite: () => ref.read(contactsProvider.notifier).toggleFavorite(contacts[i].id),
                      ),
                    )
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (ctx, i) {
                        final c = contacts[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: c.isFavorite ? Colors.amber.shade100 : null,
                            child: Text(c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?'),
                          ),
                          title: Text(c.displayName),
                          subtitle: Text([c.email, c.phone, c.company].where((s) => s.isNotEmpty).join(' · ')),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: Icon(c.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: c.isFavorite ? Colors.red : null, size: 20),
                              onPressed: () => ref.read(contactsProvider.notifier).toggleFavorite(c.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => ref.read(contactsProvider.notifier).deleteContact(c.id),
                            ),
                          ]),
                          onTap: () => _showContactDetail(context, c),
                        );
                      },
                    ),
    );
  }

  void _showContactDetail(BuildContext context, ContactModel contact) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 32, child: Text(contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?')),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(contact.displayName, style: theme.textTheme.titleLarge),
                if (contact.jobTitle.isNotEmpty) Text(contact.jobTitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                if (contact.company.isNotEmpty) Text(contact.company, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
              ])),
              IconButton(
                icon: Icon(contact.isFavorite ? Icons.favorite : Icons.favorite_border, color: contact.isFavorite ? Colors.red : null),
                onPressed: () { ref.read(contactsProvider.notifier).toggleFavorite(contact.id); Navigator.pop(ctx); },
              ),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            if (contact.email.isNotEmpty) ListTile(leading: const Icon(Icons.email), title: Text(contact.email), onTap: () {}),
            if (contact.phone.isNotEmpty) ListTile(leading: const Icon(Icons.phone), title: Text(contact.phone)),
            if (contact.address.isNotEmpty) ListTile(leading: const Icon(Icons.location_on), title: Text(contact.address)),
            if (contact.birthday.isNotEmpty) ListTile(leading: const Icon(Icons.cake), title: Text('Birthday: ${contact.birthday}')),
            if (contact.notes.isNotEmpty) ...[
              const Divider(),
              Padding(padding: const EdgeInsets.all(16), child: Text('Notes', style: theme.textTheme.titleSmall)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(contact.notes)),
            ],
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FilledButton.tonal(onPressed: () { Navigator.pop(ctx); context.push('/contacts/${contact.id}/messages'); }, child: const Text('Message')),
              FilledButton.tonal(onPressed: () { Navigator.pop(ctx); _showEditDialog(context, contact); }, child: const Text('Edit')),
              TextButton(onPressed: () { Navigator.pop(ctx); ref.read(contactsProvider.notifier).deleteContact(contact.id); },
                child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final jobCtrl = TextEditingController();
    final bdayCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Contact'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'First Name')),
        TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
        TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
        TextField(controller: jobCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
        TextField(controller: bdayCtrl, decoration: const InputDecoration(labelText: 'Birthday (YYYY-MM-DD)')),
        TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(contactsProvider.notifier).createContact(ContactModel(
            id: '', firstName: firstCtrl.text, lastName: lastCtrl.text,
            email: emailCtrl.text, phone: phoneCtrl.text, company: companyCtrl.text,
            jobTitle: jobCtrl.text, birthday: bdayCtrl.text, address: addressCtrl.text,
          ));
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  void _showEditDialog(BuildContext context, ContactModel contact) {
    final firstCtrl = TextEditingController(text: contact.firstName);
    final lastCtrl = TextEditingController(text: contact.lastName);
    final emailCtrl = TextEditingController(text: contact.email);
    final phoneCtrl = TextEditingController(text: contact.phone);
    final companyCtrl = TextEditingController(text: contact.company);
    final jobCtrl = TextEditingController(text: contact.jobTitle);
    final bdayCtrl = TextEditingController(text: contact.birthday);
    final addressCtrl = TextEditingController(text: contact.address);

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit Contact'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'First Name')),
        TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
        TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
        TextField(controller: jobCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
        TextField(controller: bdayCtrl, decoration: const InputDecoration(labelText: 'Birthday (YYYY-MM-DD)')),
        TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(contactsProvider.notifier).updateContact(contact.copyWith(
            firstName: firstCtrl.text, lastName: lastCtrl.text,
            email: emailCtrl.text, phone: phoneCtrl.text, company: companyCtrl.text,
            jobTitle: jobCtrl.text, birthday: bdayCtrl.text, address: addressCtrl.text,
            displayName: '${firstCtrl.text} ${lastCtrl.text}'.trim(),
          ));
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  void _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final content = await file.xFile.readAsString();
    if (file.extension == 'csv') {
      // Convert CSV to JSON array
      final lines = content.trim().split('\n');
      if (lines.length < 2) return;
      final headers = lines[0].split(',').map((h) => h.trim().replaceAll('"', '')).toList();
      final jsonList = lines.skip(1).map((line) {
        final values = line.split(',').map((v) => v.trim().replaceAll('"', '')).toList();
        final map = <String, dynamic>{};
        for (int i = 0; i < headers.length && i < values.length; i++) {
          map[headers[i]] = values[i];
        }
        return map;
      }).toList();
      final jsonStr = jsonList.map((m) => m.toString()).join(',');
      ref.read(contactsProvider.notifier).importContacts('[$jsonStr]');
    } else {
      ref.read(contactsProvider.notifier).importContacts(content);
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Importing contacts...')));
  }
}

class _ContactGridCard extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _ContactGridCard({required this.contact, required this.onTap, required this.onFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(children: [
              CircleAvatar(radius: 28, child: Text(contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?')),
              if (contact.isFavorite) Positioned(top: 0, right: 0, child: Icon(Icons.favorite, color: Colors.red, size: 16)),
            ]),
            const SizedBox(height: 8),
            Text(contact.displayName, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (contact.email.isNotEmpty) Text(contact.email, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (contact.phone.isNotEmpty) Text(contact.phone, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ]),
        ),
      ),
    );
  }
}
