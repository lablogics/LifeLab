import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/albums_providers.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});
  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(albumsProvider.notifier).loadAlbums();
      setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(albumsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(albumsProvider.notifier).refresh()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: albums.isLoading
          ? const Center(child: CircularProgressIndicator())
          : albums.albums.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.photo_album, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No albums yet'),
                ]))
              : RefreshIndicator(
                  onRefresh: () => ref.read(albumsProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12),
                    itemCount: albums.albums.length,
                    itemBuilder: (ctx, i) {
                      final album = albums.albums[i];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showAlbumDetail(album),
                          onLongPress: () => _showAlbumActions(album),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Center(child: Icon(Icons.photo_album, size: 48, color: theme.colorScheme.outline)),
                              )),
                              Padding(padding: const EdgeInsets.all(12), child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(album.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (album.photoCount != null)
                                    Text('${album.photoCount} photos', style: theme.textTheme.bodySmall),
                                ],
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showCreateDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New Album'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Album name'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(albumsProvider.notifier).createAlbum(ctrl.text.trim());
          Navigator.pop(ctx);
        }, child: const Text('Create')),
      ],
    ));
  }

  void _showAlbumDetail(AlbumModel album) {
    showModalBottomSheet(context: context, builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(album.name, style: Theme.of(ctx).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (album.photoCount != null) Text('${album.photoCount} photos'),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {
            Navigator.pop(ctx);
            _showRenameDialog(album);
          }),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
            Navigator.pop(ctx);
            _confirmDelete(album);
          }),
        ]),
      ]),
    ));
  }

  void _showAlbumActions(AlbumModel album) => _showAlbumDetail(album);

  void _showRenameDialog(AlbumModel album) {
    final ctrl = TextEditingController(text: album.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Rename Album'),
      content: TextField(controller: ctrl, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(albumsProvider.notifier).renameAlbum(album.id, ctrl.text.trim());
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  void _confirmDelete(AlbumModel album) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Album'),
      content: Text('Delete "${album.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton.tonal(onPressed: () {
          ref.read(albumsProvider.notifier).deleteAlbum(album.id);
          Navigator.pop(ctx);
        }, child: const Text('Delete')),
      ],
    ));
  }
}
