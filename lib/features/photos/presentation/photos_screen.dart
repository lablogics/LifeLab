import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/photos_providers.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'photo_share_dialog.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});
  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  String? _selectedStorageId;
  bool _bulkMode = false;
  final Set<String> _selectedIds = {};
  final _picker = ImagePicker();

  @override
  void initState() { super.initState(); Future.microtask(() => ref.read(photosProvider.notifier).loadPhotos()); }

  Future<void> _pickAndUpload(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;
    if (!mounted) return;
    ref.read(photosProvider.notifier).uploadPhoto(image.path, storageId: _selectedStorageId);
  }

  void _showUploadOptions() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.bold))),
      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(ctx); _pickAndUpload(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(ctx); _pickAndUpload(ImageSource.gallery); }),
    ])));
  }

  void _showJumpToDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Jump to date',
    );
    if (date != null) {
      // Scroll to photos taken around that date
      final photos = ref.read(photosProvider).photos;
      final target = date.millisecondsSinceEpoch;
      final closest = photos.where((p) => p.takenAt != null).toList()
        ..sort((a, b) => ((a.takenAt! - target).abs()).compareTo((b.takenAt! - target).abs()));
      if (closest.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nearest photo: ${DateTime.fromMillisecondsSinceEpoch(closest.first.takenAt!).toLocal().toString().substring(0, 10)}')),
        );
      }
    }
  }

  void _showImportToAlbum() async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.photos}/albums');
      final albums = ((r.data as Map<String, dynamic>)['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (albums.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No albums found. Create one first.')));
        return;
      }
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Import to Album'),
          children: albums.map((a) => SimpleDialogOption(
            child: Text(a['name'] as String? ?? 'Album'),
            onPressed: () => Navigator.pop(ctx, a['id'] as String),
          )).toList(),
        ),
      );
      if (selected != null && _selectedIds.isNotEmpty) {
        for (final photoId in _selectedIds) {
          await api.dio.dio.post('${Endpoints.photos}/albums/$selected/photos', data: {'photoId': photoId});
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedIds.length} photo(s) added to album')));
          setState(() { _selectedIds.clear(); _bulkMode = false; });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final storages = ref.watch(storagesProvider);
    final photos = ref.watch(photosProvider);
    final theme = Theme.of(context);
    final items = photos.filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos'),
        actions: [
          if (photos.uploading) const Padding(padding: EdgeInsets.only(right: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          if (_bulkMode) ...[
            TextButton(onPressed: () { _selectedIds.clear(); setState(() => _bulkMode = false); }, child: const Text('Cancel')),
            if (_selectedIds.isNotEmpty) ...[
              IconButton(icon: const Icon(Icons.delete), tooltip: 'Delete selected', onPressed: () async {
                for (final id in _selectedIds) { ref.read(photosProvider.notifier).trashPhoto(id); }
                setState(() { _selectedIds.clear(); _bulkMode = false; });
              }),
              IconButton(icon: const Icon(Icons.photo_album), tooltip: 'Add to album', onPressed: _showImportToAlbum),
            ],
          ] else ...[
            IconButton(icon: const Icon(Icons.checklist), tooltip: 'Select', onPressed: () => setState(() => _bulkMode = true)),
            IconButton(icon: const Icon(Icons.date_range), tooltip: 'Jump to date', onPressed: _showJumpToDate),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(photosProvider.notifier).refresh()),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_bulkMode ? 48 : 96),
          child: _bulkMode
              ? Padding(padding: const EdgeInsets.all(8), child: Text('${_selectedIds.length} selected', style: theme.textTheme.bodyMedium))
              : Column(children: [
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                    _viewChip('All', PhotosView.all, photos.view),
                    _viewChip('Starred', PhotosView.starred, photos.view),
                    _viewChip('Favorites', PhotosView.favorites, photos.view),
                    _viewChip('Trash', PhotosView.trash, photos.view),
                  ])),
                  const SizedBox(height: 4),
                  Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: TextField(
                    decoration: const InputDecoration(hintText: 'Search photos...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => ref.read(photosProvider.notifier).searchPhotos(v),
                  )),
                  if (storages.storages.isNotEmpty)
                    Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: DropdownButtonFormField<String>(
                      value: _selectedStorageId, decoration: const InputDecoration(labelText: 'Storage', isDense: true, border: OutlineInputBorder()),
                      items: storages.storages.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String? ?? 'Storage'))).toList(),
                      onChanged: (v) { setState(() => _selectedStorageId = v); ref.read(photosProvider.notifier).loadPhotos(storageId: v); },
                    )),
                ]),
        ),
      ),
      floatingActionButton: _bulkMode ? null : FloatingActionButton(onPressed: _showUploadOptions, child: const Icon(Icons.add_a_photo)),
      body: photos.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_library, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No photos')]))
              : RefreshIndicator(
                  onRefresh: () => ref.read(photosProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final p = items[i];
                      final selected = _selectedIds.contains(p.id);
                      return GestureDetector(
                        onTap: () {
                          if (_bulkMode) {
                            setState(() { selected ? _selectedIds.remove(p.id) : _selectedIds.add(p.id); });
                          } else {
                            _showPhotoDetail(p);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: selected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                          ),
                          child: Stack(children: [
                            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.image, color: theme.colorScheme.outline),
                              const SizedBox(height: 4),
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                            ])),
                            if (_bulkMode) Positioned(top: 4, left: 4, child: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: selected ? theme.colorScheme.primary : theme.colorScheme.outline)),
                            if (p.starred) Positioned(top: 4, right: 4, child: Icon(Icons.star, color: Colors.amber, size: 16)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatPhotoSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _viewChip(String label, PhotosView view, PhotosView current) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FilterChip(
      label: Text(label), selected: view == current,
      onSelected: (_) => ref.read(photosProvider.notifier).setView(view),
    ));
  }

  void _showPhotoDetail(PhotoModel photo) {
    showModalBottomSheet(context: context, builder: (ctx) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(photo.name, style: Theme.of(ctx).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (photo.size != null) Text(_formatPhotoSize(photo.size)),
      if (photo.width != null) Text('Dimensions: ${photo.width}x${photo.height}'),
      if (photo.cameraModel != null) Text('Camera: ${photo.cameraModel}'),
      if (photo.takenAt != null) Text('Taken: ${DateTime.fromMillisecondsSinceEpoch(photo.takenAt!).toLocal()}'),
      if (photo.latitude != null) Text('Location: ${photo.latitude}, ${photo.longitude}'),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: Icon(photo.starred ? Icons.star : Icons.star_border), onPressed: () { ref.read(photosProvider.notifier).toggleStar(photo.id); Navigator.pop(ctx); }),
        IconButton(icon: Icon(photo.favorite ? Icons.favorite : Icons.favorite_border, color: photo.favorite ? Colors.red : null), onPressed: () { ref.read(photosProvider.notifier).toggleFavorite(photo.id); }),
        IconButton(icon: const Icon(Icons.share), onPressed: () { showDialog(context: context, builder: (_) => PhotoShareDialog(photoId: photo.id, photoName: photo.name)); }),
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { ref.read(photosProvider.notifier).trashPhoto(photo.id); Navigator.pop(ctx); }),
        if (photo.trashed) IconButton(icon: const Icon(Icons.restore), onPressed: () { ref.read(photosProvider.notifier).restorePhoto(photo.id); Navigator.pop(ctx); }),
      ]),
    ])));
  }
}
