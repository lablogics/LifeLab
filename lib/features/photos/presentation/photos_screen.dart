import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/photos_providers.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});
  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  String? _selectedStorageId;

  @override
  Widget build(BuildContext context) {
    final storages = ref.watch(storagesProvider);
    final photos = ref.watch(photosProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Photos'), actions: [
        if (storages.storages.isNotEmpty)
          DropdownButton<String>(value: _selectedStorageId, hint: const Text('Storage'), items: storages.storages.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String? ?? 'Storage'))).toList(), onChanged: (v) { if (v != null) { setState(() => _selectedStorageId = v); ref.read(photosProvider.notifier).loadPhotos(v); } }),
      ]),
      body: _selectedStorageId == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_library, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('Select a storage to view photos')]))
          : photos.isLoading
              ? const Center(child: CircularProgressIndicator())
              : photos.photos.isEmpty
                  ? Center(child: Text('No photos', style: theme.textTheme.bodyLarge))
                  : GridView.builder(padding: const EdgeInsets.all(4), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4), itemCount: photos.photos.length, itemBuilder: (ctx, i) {
                      final p = photos.photos[i];
                      return Container(decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image, color: theme.colorScheme.outline), const SizedBox(height: 4), Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall)])));
                    }),
    );
  }
}
