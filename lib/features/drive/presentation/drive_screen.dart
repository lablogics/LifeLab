import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/drive_providers.dart';
import '../../photos/data/photos_providers.dart';

class DriveScreen extends ConsumerStatefulWidget {
  const DriveScreen({super.key});
  @override
  ConsumerState<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends ConsumerState<DriveScreen> {
  String? _selectedStorageId;

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    if (!mounted) return;
    ref.read(driveProvider.notifier).uploadFile(file.path!);
  }

  @override
  Widget build(BuildContext context) {
    final storages = ref.watch(storagesProvider);
    final drive = ref.watch(driveProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(drive.pathNames.isEmpty ? 'Drive' : drive.pathNames.join(' / ')),
        leading: drive.path.isNotEmpty ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => ref.read(driveProvider.notifier).goBack()) : null,
        actions: [
          if (drive.uploading) const Padding(padding: EdgeInsets.only(right: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(driveProvider.notifier).refresh()),
          IconButton(icon: const Icon(Icons.create_new_folder_outlined), onPressed: _showCreateFolderDialog),
          IconButton(icon: const Icon(Icons.upload_file), onPressed: _pickAndUpload),
          IconButton(icon: Icon(drive.starred ? Icons.star : Icons.star_border), tooltip: 'Starred', onPressed: () => ref.read(driveProvider.notifier).setStarredView(!drive.starred)),
          IconButton(icon: Icon(drive.trashed ? Icons.delete : Icons.delete_outline), tooltip: 'Trash', onPressed: () => ref.read(driveProvider.notifier).setTrashView(!drive.trashed)),
        ],
      ),
      body: _selectedStorageId == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.folder_open, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              const Text('Select a storage to browse files'),
              const SizedBox(height: 24),
              if (storages.storages.isNotEmpty)
                DropdownButton<String>(value: _selectedStorageId, hint: const Text('Storage'),
                  items: storages.storages.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String? ?? 'Storage'))).toList(),
                  onChanged: (v) { if (v != null) { setState(() => _selectedStorageId = v); ref.read(driveProvider.notifier).setStorage(v); } }),
            ]))
          : drive.isLoading
              ? const Center(child: CircularProgressIndicator())
              : drive.items.isEmpty
                  ? Center(child: Text('Empty folder', style: theme.textTheme.bodyLarge))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(driveProvider.notifier).refresh(),
                      child: ListView.builder(
                        itemCount: drive.items.length,
                        itemBuilder: (ctx, i) {
                          final item = drive.items[i];
                          final isFolder = item.type == 'folder';
                          return ListTile(
                            leading: Icon(isFolder ? Icons.folder : _iconForFile(item.name), color: isFolder ? Colors.amber : theme.colorScheme.outline),
                            title: Text(item.name, semanticsLabel: 'File ${item.name}'),
                            subtitle: Text(isFolder ? 'Folder' : _formatSize(item.size)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) => _handleItemAction(v, item),
                              itemBuilder: (_) => [
                                if (!isFolder) const PopupMenuItem(value: 'open', child: Text('Open')),
                                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                const PopupMenuItem(value: 'star', child: Text('Star')),
                                const PopupMenuItem(value: 'trash', child: Text('Move to Trash')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                            onTap: isFolder ? () => ref.read(driveProvider.notifier).loadFolder(item.id, item.name) : () => _openFile(item),
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _iconForFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg': case 'jpeg': case 'png': case 'gif': return Icons.image;
      case 'mp4': case 'mov': case 'avi': return Icons.videocam;
      case 'mp3': case 'wav': case 'flac': return Icons.audiotrack;
      case 'doc': case 'docx': return Icons.description;
      case 'xls': case 'xlsx': return Icons.table_chart;
      default: return Icons.insert_drive_file;
    }
  }

  Future<void> _openFile(DriveItem item) async {
    final url = await ref.read(driveProvider.notifier).getDownloadUrl(item.id);
    if (url != null && mounted) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file')));
    }
  }

  void _showCreateFolderDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New Folder'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Folder name'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { ref.read(driveProvider.notifier).createFolder(ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('Create')),
      ],
    ));
  }

  void _handleItemAction(String action, DriveItem item) {
    switch (action) {
      case 'open':
        _openFile(item);
        break;
      case 'rename':
        final ctrl = TextEditingController(text: item.name);
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Rename'),
          content: TextField(controller: ctrl, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () { ref.read(driveProvider.notifier).renameItem(item.id, ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('Save')),
          ],
        ));
        break;
      case 'star':
        ref.read(driveProvider.notifier).starItem(item.id);
        break;
      case 'trash':
        ref.read(driveProvider.notifier).trashItem(item.id);
        break;
      case 'delete':
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Delete'),
          content: Text('Delete "${item.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.tonal(onPressed: () { ref.read(driveProvider.notifier).deleteItem(item.id); Navigator.pop(ctx); }, child: const Text('Delete')),
          ],
        ));
        break;
    }
  }
}
