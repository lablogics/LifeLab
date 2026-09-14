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
              return ListTile(
                leading: CircleAvatar(child: Text(mail.from[0].toUpperCase())),
                title: Text(mail.subject, style: TextStyle(fontWeight: mail.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text('${mail.to} - ${mail.body}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: Icon(mail.isStarred ? Icons.star : Icons.star_border, color: mail.isStarred ? Colors.amber : null, size: 18), onPressed: () => notifier.toggleStar(mail.id)),
                  if (mail.attachments.isNotEmpty) const Icon(Icons.attach_file, size: 16),
                  PopupMenuButton<String>(onSelected: (v) {
                    switch (v) {
                      case 'trash': notifier.moveToTrash(mail.id);
                      case 'archive': notifier.moveToArchive(mail.id);
                      case 'spam': notifier.moveToSpam(mail.id);
                      case 'delete': notifier.deletePermanently(mail.id);
                      default: break;
                    }
                  }, itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'archive', child: Text('Archive')),
                    const PopupMenuItem(value: 'spam', child: Text('Spam')),
                    const PopupMenuItem(value: 'trash', child: Text('Move to Trash')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ]),
                ]),
                onTap: () { notifier.markRead(mail.id); _showMailDetail(context, mail, ref); },
              );
            }),
    );
  }

  IconData _folderIcon(MailFolder f) => switch (f) { MailFolder.inbox => Icons.inbox, MailFolder.sent => Icons.send, MailFolder.drafts => Icons.drafts, MailFolder.trash => Icons.delete, MailFolder.archive => Icons.archive, MailFolder.spam => Icons.report };

  void _showMailDetail(BuildContext context, MailModel mail, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(mail.subject),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('From: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(mail.from)),
        ]),
        Row(children: [
          Text('To: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(mail.to)),
        ]),
        if (mail.attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...mail.attachments.map((a) => Row(children: [const Icon(Icons.attach_file, size: 14), const SizedBox(width: 4), Text(a, style: theme.textTheme.bodySmall)])),
        ],
        const Divider(),
        Text(mail.body),
      ])),
      actions: [
        IconButton(icon: Icon(mail.isStarred ? Icons.star : Icons.star_border, color: mail.isStarred ? Colors.amber : null), onPressed: () { ref.read(mailProvider.notifier).toggleStar(mail.id); Navigator.pop(ctx); }),
        TextButton(onPressed: () { Navigator.pop(ctx); _showReplyDialog(context, mail, false, ref); }, child: const Text('Reply')),
        TextButton(onPressed: () { Navigator.pop(ctx); _showReplyDialog(context, mail, true, ref); }, child: const Text('Forward')),
        TextButton(onPressed: () { ref.read(mailProvider.notifier).moveToArchive(mail.id); Navigator.pop(ctx); }, child: const Text('Archive')),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ));
  }

  void _showReplyDialog(BuildContext context, MailModel mail, bool isForward, WidgetRef ref) {
    final bodyCtrl = TextEditingController();
    final prefix = isForward ? 'Fwd' : 'Re';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('$prefix: ${mail.subject}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!isForward) Text('To: ${mail.from}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('--- Original message ---', style: TextStyle(color: Theme.of(ctx).colorScheme.outline)),
        Text(mail.body, style: TextStyle(color: Theme.of(ctx).colorScheme.outline)),
        const SizedBox(height: 8),
        TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Your reply'), maxLines: 5),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(mailProvider.notifier).sendMail(isForward ? mail.to : mail.from, '$prefix: ${mail.subject}', bodyCtrl.text);
          Navigator.pop(ctx);
        }, child: const Text('Send')),
      ],
    ));
  }

  void _showComposeDialog(BuildContext context, WidgetRef ref) {
    final toCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Compose'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To')), TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')), TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Body'), maxLines: 5)])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () { ref.read(mailProvider.notifier).saveDraft(toCtrl.text, subjectCtrl.text, bodyCtrl.text); Navigator.pop(ctx); }, child: const Text('Save Draft')), FilledButton(onPressed: () { ref.read(mailProvider.notifier).sendMail(toCtrl.text, subjectCtrl.text, bodyCtrl.text); Navigator.pop(ctx); }, child: const Text('Send'))]));
  }
}
