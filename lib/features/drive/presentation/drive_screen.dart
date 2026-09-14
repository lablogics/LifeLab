import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import '../data/drive_providers.dart';
import '../../photos/data/photos_providers.dart';

class DriveScreen extends ConsumerStatefulWidget {
  const DriveScreen({super.key});
  @override
  ConsumerState<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends ConsumerState<DriveScreen> {
  String? _selectedStorageId;
  bool _isGridView = false;

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showToast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
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
    final totalSize = drive.items.fold<int>(0, (sum, item) => sum + (item.size ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text(drive.pathNames.isEmpty ? 'Drive' : drive.pathNames.last),
        leading: drive.path.isNotEmpty ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => ref.read(driveProvider.notifier).goBack()) : null,
        actions: [
          if (drive.uploading) const Padding(padding: EdgeInsets.only(right: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { ref.read(driveProvider.notifier).refresh(); _showToast('Refreshed'); }),
          IconButton(icon: const Icon(Icons.create_new_folder_outlined), onPressed: _showCreateFolderDialog),
          IconButton(icon: const Icon(Icons.upload_file), onPressed: _pickAndUpload),
          IconButton(icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view), tooltip: _isGridView ? 'List view' : 'Grid view', onPressed: () => setState(() => _isGridView = !_isGridView)),
          IconButton(icon: Icon(drive.starred ? Icons.star : Icons.star_border), tooltip: 'Starred', onPressed: () => ref.read(driveProvider.notifier).setStarredView(!drive.starred)),
          IconButton(icon: Icon(drive.trashed ? Icons.delete : Icons.delete_outline), tooltip: 'Trash', onPressed: () => ref.read(driveProvider.notifier).setTrashView(!drive.trashed)),
          if (drive.trashed) IconButton(icon: const Icon(Icons.delete_sweep), tooltip: 'Empty trash', onPressed: _emptyTrash),
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
              : Column(children: [
                  // Breadcrumbs
                  if (drive.pathNames.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Row(children: [
                        InkWell(onTap: () => ref.read(driveProvider.notifier).loadFolder(null, ''), child: const Text('Drive', style: TextStyle(color: Colors.blue))),
                        for (int i = 0; i < drive.pathNames.length; i++) ...[
                          const Text(' / '),
                          if (i < drive.pathNames.length - 1)
                            InkWell(onTap: () { ref.read(driveProvider.notifier).loadFolder(drive.path[i], drive.pathNames[i]); },
                              child: Text(drive.pathNames[i], style: const TextStyle(color: Colors.blue)))
                          else
                            Text(drive.pathNames[i]),
                        ],
                      ]),
                    ),
                  // Storage stats
                  if (drive.items.isNotEmpty)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(children: [
                        Text('${drive.items.length} items', style: theme.textTheme.bodySmall),
                        const Spacer(),
                        Text(_formatSize(totalSize), style: theme.textTheme.bodySmall),
                      ]),
                    ),
                  // Items
                  Expanded(
                    child: drive.items.isEmpty
                      ? Center(child: Text('Empty folder', style: theme.textTheme.bodyLarge))
                      : RefreshIndicator(
                          onRefresh: () => ref.read(driveProvider.notifier).refresh(),
                          child: _isGridView
                              ? GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                                  itemCount: drive.items.length,
                                  itemBuilder: (ctx, i) => _buildGridItem(drive.items[i], theme),
                                )
                              : ListView.builder(
                                  itemCount: drive.items.length,
                                  itemBuilder: (ctx, i) => _buildListItem(drive.items[i], theme),
                                ),
                        ),
                  ),
                ]),
    );
  }

  Widget _buildListItem(DriveItem item, ThemeData theme) {
    final isFolder = item.type == 'folder';
    final isImage = !isFolder && RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false).hasMatch(item.name);
    return ListTile(
      leading: isImage
          ? item.url != null ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(item.url!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, color: theme.colorScheme.outline))) : Icon(Icons.image, color: theme.colorScheme.outline)
          : Icon(isFolder ? Icons.folder : _iconForFile(item.name), color: isFolder ? Colors.amber : theme.colorScheme.outline),
      title: Text(item.name, semanticsLabel: 'File ${item.name}'),
      subtitle: Text(isFolder ? 'Folder' : _formatSize(item.size)),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => _handleItemAction(v, item),
        itemBuilder: (_) => [
          if (!isFolder) const PopupMenuItem(value: 'open', child: Text('Open')),
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          const PopupMenuItem(value: 'star', child: Text('Star')),
          if (ref.read(driveProvider).trashed) const PopupMenuItem(value: 'restore', child: Text('Restore')),
          const PopupMenuItem(value: 'trash', child: Text('Move to Trash')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: isFolder ? () => ref.read(driveProvider.notifier).loadFolder(item.id, item.name) : () => _openFile(item),
    );
  }

  Widget _buildGridItem(DriveItem item, ThemeData theme) {
    final isFolder = item.type == 'folder';
    final isImage = !isFolder && RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false).hasMatch(item.name);
    return InkWell(
      onTap: isFolder ? () => ref.read(driveProvider.notifier).loadFolder(item.id, item.name) : () => _openFile(item),
      onLongPress: () => _previewImage(item, theme),
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isImage && item.url != null)
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), child: Image.network(item.url!, height: 60, width: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, size: 40, color: theme.colorScheme.outline)))
          else
            Icon(isFolder ? Icons.folder : _iconForFile(item.name), size: 40, color: isFolder ? Colors.amber : theme.colorScheme.outline),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
        ]),
      ),
    );
  }

  void _previewImage(DriveItem item, ThemeData theme) async {
    final isImage = RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false).hasMatch(item.name);
    if (!isImage || item.url == null) return;
    final url = await ref.read(driveProvider.notifier).getDownloadUrl(item.id);
    if (url != null && mounted) {
      showDialog(context: context, builder: (ctx) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64))),
          Padding(padding: const EdgeInsets.all(8), child: Text(item.name, style: theme.textTheme.bodySmall)),
        ]),
      ));
    }
  }

  void _emptyTrash() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Empty Trash'),
      content: const Text('All items in trash will be permanently deleted. This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Empty Trash')),
      ],
    ));
    if (confirmed == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.dio.dio.delete('${Endpoints.drive}/trash');
        ref.read(driveProvider.notifier).refresh();
        _showToast('Trash emptied');
      } catch (e) {
        _showToast('Failed to empty trash: $e');
      }
    }
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
            FilledButton(onPressed: () { ref.read(driveProvider.notifier).renameItem(item.id, ctrl.text.trim()); Navigator.pop(ctx); _showToast('Renamed'); }, child: const Text('Save')),
          ],
        ));
        break;
      case 'star':
        ref.read(driveProvider.notifier).starItem(item.id);
        _showToast('Starred');
        break;
      case 'restore':
        ref.read(driveProvider.notifier).restoreItem(item.id);
        _showToast('Restored');
        break;
      case 'trash':
        ref.read(driveProvider.notifier).trashItem(item.id);
        _showToast('Moved to trash');
        break;
      case 'delete':
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Delete'),
          content: Text('Delete "${item.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.tonal(onPressed: () { ref.read(driveProvider.notifier).deleteItem(item.id); Navigator.pop(ctx); _showToast('Deleted'); }, child: const Text('Delete')),
          ],
        ));
        break;
    }
  }
}
