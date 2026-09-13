import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mail_providers.dart';

class MailScreen extends ConsumerWidget {
  const MailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mailProvider);
    final notifier = ref.read(mailProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mail'), actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => _showComposeDialog(context, ref))]),
      drawer: Drawer(child: SafeArea(child: Column(children: [
        const SizedBox(height: 16),
        Text('Folders', style: theme.textTheme.titleMedium),
        const Divider(),
        ...MailFolder.values.map((f) => ListTile(leading: Icon(_folderIcon(f)), title: Text(f.name[0].toUpperCase() + f.name.substring(1)), selected: state.currentFolder == f, onTap: () { notifier.selectFolder(f); Navigator.pop(context); })),
      ]))),
      body: state.filtered.isEmpty
          ? Center(child: Text('No emails in ${state.currentFolder.name}', style: theme.textTheme.bodyLarge))
          : ListView.builder(itemCount: state.filtered.length, itemBuilder: (ctx, i) {
              final mail = state.filtered[i];
              return ListTile(leading: CircleAvatar(child: Text(mail.from[0].toUpperCase())), title: Text(mail.subject, style: TextStyle(fontWeight: mail.isRead ? FontWeight.normal : FontWeight.bold)), subtitle: Text('${mail.to} - ${mail.body}', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'trash') notifier.moveToTrash(mail.id); else if (v == 'delete') notifier.deletePermanently(mail.id); }, itemBuilder: (ctx) => [const PopupMenuItem(value: 'trash', child: Text('Move to Trash')), const PopupMenuItem(value: 'delete', child: Text('Delete'))]), onTap: () { notifier.markRead(mail.id); _showMailDetail(context, mail); });
            }),
    );
  }

  IconData _folderIcon(MailFolder f) => switch (f) { MailFolder.inbox => Icons.inbox, MailFolder.sent => Icons.send, MailFolder.drafts => Icons.drafts, MailFolder.trash => Icons.delete };

  void _showMailDetail(BuildContext context, MailModel mail) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(mail.subject), content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('From: ${mail.from}'), Text('To: ${mail.to}'), const Divider(), Text(mail.body)])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]));
  }

  void _showComposeDialog(BuildContext context, WidgetRef ref) {
    final toCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Compose'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To')), TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')), TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Body'), maxLines: 5)])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () { ref.read(mailProvider.notifier).saveDraft(toCtrl.text, subjectCtrl.text, bodyCtrl.text); Navigator.pop(ctx); }, child: const Text('Save Draft')), FilledButton(onPressed: () { ref.read(mailProvider.notifier).sendMail(toCtrl.text, subjectCtrl.text, bodyCtrl.text); Navigator.pop(ctx); }, child: const Text('Send'))]));
  }
}
