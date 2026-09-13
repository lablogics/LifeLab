import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/attachments_providers.dart';

class AttachmentsScreen extends ConsumerStatefulWidget {
  final String noteId;
  const AttachmentsScreen({super.key, required this.noteId});
  @override
  ConsumerState<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends ConsumerState<AttachmentsScreen> {
  @override
  void initState() { super.initState(); Future.microtask(() => ref.read(attachmentsProvider.notifier).loadAttachments(widget.noteId)); }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attachmentsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Attachments')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.attachments.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.attach_file, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No attachments')]))
              : ListView.builder(
                  itemCount: state.attachments.length,
                  itemBuilder: (ctx, i) {
                    final a = state.attachments[i];
                    return ListTile(
                      leading: Icon(_iconForMime(a.mimeType), color: theme.colorScheme.primary),
                      title: Text(a.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_formatSize(a.size)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                        final ok = await ref.read(attachmentsProvider.notifier).deleteAttachment(a.id);
                        if (ok) ref.read(attachmentsProvider.notifier).loadAttachments(widget.noteId);
                      }),
                    );
                  },
                ),
    );
  }

  IconData _iconForMime(String? mime) {
    if (mime == null) return Icons.insert_drive_file;
    if (mime.startsWith('image/')) return Icons.image;
    if (mime.startsWith('video/')) return Icons.videocam;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }
}
