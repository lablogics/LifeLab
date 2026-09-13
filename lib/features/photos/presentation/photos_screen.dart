import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/photos_providers.dart';
import 'photo_share_dialog.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});
  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  String? _selectedStorageId;

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
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(photosProvider.notifier).refresh()),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(children: [
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
      floatingActionButton: FloatingActionButton(onPressed: _showUploadOptions, child: const Icon(Icons.add_a_photo)),
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
                      return GestureDetector(
                        onTap: () => _showPhotoDetail(p),
                        child: Container(
                          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                          child: Stack(children: [
                            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.image, color: theme.colorScheme.outline),
                              const SizedBox(height: 4),
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                            ])),
                            if (p.starred) Positioned(top: 4, right: 4, child: Icon(Icons.star, color: Colors.amber, size: 16)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
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
      if (photo.width != null) Text('${photo.width}x${photo.height}'),
      if (photo.cameraModel != null) Text('Camera: ${photo.cameraModel}'),
      if (photo.takenAt != null) Text('Taken: ${DateTime.fromMillisecondsSinceEpoch(photo.takenAt!).toLocal()}'),
      if (photo.latitude != null) Text('Location: ${photo.latitude}, ${photo.longitude}'),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: Icon(photo.starred ? Icons.star : Icons.star_border), onPressed: () { ref.read(photosProvider.notifier).toggleStar(photo.id); Navigator.pop(ctx); }),
        IconButton(icon: const Icon(Icons.share), onPressed: () { showDialog(context: context, builder: (_) => PhotoShareDialog(photoId: photo.id, photoName: photo.name)); }),
        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { ref.read(photosProvider.notifier).trashPhoto(photo.id); Navigator.pop(ctx); }),
        if (photo.trashed) IconButton(icon: const Icon(Icons.restore), onPressed: () { ref.read(photosProvider.notifier).restorePhoto(photo.id); Navigator.pop(ctx); }),
      ]),
    ])));
  }
}
