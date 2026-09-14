import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _showTimeline = false;
  String _searchFilter = ''; // date, type, name
  DateTimeRange? _dateFilterRange;

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
      ListTile(leading: const Icon(Icons.photo_album), title: const Text('Upload to Album'), onTap: () { Navigator.pop(ctx); _uploadToAlbum(); }),
    ])));
  }

  void _uploadToAlbum() async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.photos}/albums');
      final albums = ((r.data as Map<String, dynamic>)['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (albums.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No albums found. Create one first.')));
        return;
      }
      final selectedAlbum = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select Album'),
          children: albums.map((a) => SimpleDialogOption(
            child: Text(a['name'] as String? ?? 'Album'),
            onPressed: () => Navigator.pop(ctx, a['id'] as String),
          )).toList(),
        ),
      );
      if (selectedAlbum == null) return;
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null || !mounted) return;
      ref.read(photosProvider.notifier).uploadPhoto(image.path, storageId: _selectedStorageId);
      // After upload, add to album
      await Future.delayed(const Duration(seconds: 2));
      final photos = ref.read(photosProvider).photos;
      if (photos.isNotEmpty) {
        await api.dio.dio.post('${Endpoints.photos}/albums/$selectedAlbum/photos', data: {'photoId': photos.first.id});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded to album')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload to album failed: $e')));
    }
  }

  void _triggerFaceDetection(String photoId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.dio.post('${Endpoints.faces}/detect', data: {'photoId': photoId});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face detection started')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Face detection failed: $e')));
    }
  }

  void _applySearchFilter(String filter) {
    if (filter == 'pick_range') {
      showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now()).then((date) {
        if (date != null) {
          setState(() => _dateFilterRange = DateTimeRange(start: date, end: date));
          ref.read(photosProvider.notifier).searchPhotos('');
        }
      });
      return;
    }
    setState(() => _searchFilter = _searchFilter == filter ? '' : filter);
    ref.read(photosProvider.notifier).searchPhotos('');
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
            IconButton(icon: const Icon(Icons.photo_album), tooltip: 'Albums', onPressed: () => _showAlbums(context)),
            IconButton(icon: const Icon(Icons.face), tooltip: 'People', onPressed: () => _showPeople(context)),
            IconButton(icon: Icon(_showTimeline ? Icons.timeline : Icons.timeline_outlined), tooltip: 'Timeline', onPressed: () => setState(() => _showTimeline = !_showTimeline)),
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
                  Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Row(children: [
                    Expanded(child: TextField(
                      decoration: const InputDecoration(hintText: 'Search photos...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) => ref.read(photosProvider.notifier).searchPhotos(v),
                    )),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (v) => _applySearchFilter(v),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'name', child: Row(children: [Icon(_searchFilter == 'name' ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18), const SizedBox(width: 8), const Text('By name')])),
                        PopupMenuItem(value: 'date', child: Row(children: [Icon(_searchFilter == 'date' ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18), const SizedBox(width: 8), const Text('By date')])),
                        PopupMenuItem(value: 'type', child: Row(children: [Icon(_searchFilter == 'type' ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18), const SizedBox(width: 8), const Text('By type')]) ),
                        if (_searchFilter == 'date') const PopupMenuItem(value: 'pick_range', child: Row(children: [Icon(Icons.date_range, size: 18), const SizedBox(width: 8), const Text('Pick date range')])),
                      ],
                    ),
                  ])),
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
              : Row(children: [
                  // Timeline sidebar
                  if (_showTimeline)
                    Container(
                      width: 48,
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, border: Border(right: BorderSide(color: theme.colorScheme.outlineVariant))),
                      child: _buildTimelineSidebar(items, theme),
                    ),
                  // Photo grid
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.read(photosProvider.notifier).refresh(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final p = items[i];
                          final selected = _selectedIds.contains(p.id);
                          final isVideo = p.mimeType != null && p.mimeType!.startsWith('video/');
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
                                  Icon(isVideo ? Icons.videocam : Icons.image, color: theme.colorScheme.outline),
                                  const SizedBox(height: 4),
                                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                                ])),
                                if (isVideo) Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.play_arrow, size: 14, color: Colors.white))),
                                if (_bulkMode) Positioned(top: isVideo ? 4 : 4, right: 4, child: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: selected ? theme.colorScheme.primary : theme.colorScheme.outline)),
                                if (!_bulkMode && p.starred) Positioned(top: 4, right: 4, child: Icon(Icons.star, color: Colors.amber, size: 16)),
                                if (p.takenAt != null) Positioned(bottom: 4, left: 4, child: Text(
                                  DateTime.fromMillisecondsSinceEpoch(p.takenAt!).toLocal().toString().substring(5, 10),
                                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, shadows: [const Shadow(blurRadius: 2, color: Colors.black)]),
                                )),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ]),
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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Expanded(child: Text(photo.name, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 16),
            // EXIF / Photo info panel
            Text('Photo Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (photo.size != null) _infoRow(Icons.data_usage, 'Size', _formatPhotoSize(photo.size)),
              if (photo.width != null && photo.height != null) _infoRow(Icons.aspect_ratio, 'Dimensions', '${photo.width} x ${photo.height}'),
              if (photo.mimeType != null) _infoRow(Icons.insert_drive_file, 'Type', photo.mimeType!),
              if (photo.cameraModel != null) _infoRow(Icons.camera_alt, 'Camera', photo.cameraModel!),
              if (photo.takenAt != null) _infoRow(Icons.date_range, 'Taken', DateTime.fromMillisecondsSinceEpoch(photo.takenAt!).toLocal().toString().substring(0, 16)),
              if (photo.latitude != null && photo.longitude != null) ...[
                _infoRow(Icons.location_on, 'Location', '${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}'),
                Padding(padding: const EdgeInsets.only(left: 24, top: 4), child: ActionChip(
                  avatar: const Icon(Icons.map, size: 14),
                  label: const Text('Open in Maps'),
                  onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps?q=${photo.latitude},${photo.longitude}')),
                )),
              ],
            ]))),
            const SizedBox(height: 16),
            // Actions
            Text('Actions', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _actionBtn(Icons.star, photo.starred ? 'Starred' : 'Star',
                color: photo.starred ? Colors.amber : null,
                onPressed: () { ref.read(photosProvider.notifier).toggleStar(photo.id); Navigator.pop(ctx); }),
              _actionBtn(Icons.favorite, photo.favorite ? 'Favorited' : 'Favorite',
                color: photo.favorite ? Colors.red : null,
                onPressed: () { ref.read(photosProvider.notifier).toggleFavorite(photo.id); Navigator.pop(ctx); }),
              _actionBtn(Icons.share, 'Share',
                onPressed: () { Navigator.pop(ctx); showDialog(context: context, builder: (_) => PhotoShareDialog(photoId: photo.id, photoName: photo.name)); }),
              _actionBtn(Icons.link, 'Copy Link',
                onPressed: () async {
                  final api = ref.read(apiClientProvider);
                  try {
                    final r = await api.dio.dio.post('${Endpoints.photos}/${photo.id}/share');
                    final link = (r.data as Map<String, dynamic>)['url'] as String? ?? '${Endpoints.photos}/${photo.id}';
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link copied: $link')));
                      Navigator.pop(ctx);
                    }
                  } catch (_) {
                    if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not generate share link'))); }
                  }
                }),
              _actionBtn(Icons.edit, 'Edit',
                onPressed: () { Navigator.pop(ctx); context.push('/photos/${photo.id}/edit'); }),
              _actionBtn(Icons.face, 'Detect Faces',
                onPressed: () { Navigator.pop(ctx); _triggerFaceDetection(photo.id); }),
              if (photo.trashed)
                _actionBtn(Icons.restore, 'Restore',
                  onPressed: () { ref.read(photosProvider.notifier).restorePhoto(photo.id); Navigator.pop(ctx); })
              else
                _actionBtn(Icons.delete_outline, 'Trash', color: Colors.red,
                  onPressed: () { ref.read(photosProvider.notifier).trashPhoto(photo.id); Navigator.pop(ctx); }),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
      const SizedBox(width: 8),
      Text('$label: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
    ]));
  }

  Widget _actionBtn(IconData icon, String label, {Color? color, required VoidCallback onPressed}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: Icon(icon, color: color), onPressed: onPressed),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }

  void _showAlbums(BuildContext context) async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.photos}/albums');
      final albums = ((r.data as Map<String, dynamic>)['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Text('Albums', style: Theme.of(ctx).textTheme.titleLarge),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add), onPressed: () { Navigator.pop(ctx); _createAlbum(context); }),
          ])),
          Expanded(child: albums.isEmpty
            ? const Center(child: Text('No albums'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: albums.length,
                itemBuilder: (_, i) {
                  final a = albums[i];
                  return ListTile(
                    leading: const Icon(Icons.photo_album),
                    title: Text(a['name'] as String? ?? 'Album'),
                    subtitle: Text('${a['photoCount'] ?? 0} photos'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      await api.dio.dio.delete('${Endpoints.photos}/albums/${a['id']}');
                      Navigator.pop(ctx);
                    }),
                    onTap: () { Navigator.pop(ctx); _showAlbumDetail(context, a); },
                  );
                },
              )),
          const SizedBox(height: 8),
        ])),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _createAlbum(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Album'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Album name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        final api = ref.read(apiClientProvider);
        await api.dio.dio.post('${Endpoints.photos}/albums', data: {'name': name});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Album created')));
      } catch (_) {}
    }
  }

  void _showAlbumDetail(BuildContext context, Map<String, dynamic> album) async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.photos}/albums/${album['id']}/photos');
      final photos = ((r.data as Map<String, dynamic>)['items'] as List? ?? (r.data as List? ?? []))
        .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
        appBar: AppBar(title: Text(album['name'] as String? ?? 'Album')),
        body: photos.isEmpty
          ? const Center(child: Text('No photos in this album'))
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: photos.length,
              itemBuilder: (_, i) {
                final p = photos[i];
                return Container(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.image, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 4),
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
                  ])),
                );
              },
            ),
      )));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showPeople(BuildContext context) async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('${Endpoints.faces}/people');
      final people = ((r.data as Map<String, dynamic>)['items'] as List? ?? (r.data as List? ?? [])).cast<Map<String, dynamic>>();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('People', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: people.isEmpty
            ? const Center(child: Text('No people detected'))
            : GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                padding: const EdgeInsets.all(16),
                itemCount: people.length,
                itemBuilder: (_, i) {
                  final p = people[i];
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 28, child: Icon(Icons.face, size: 28)),
                    const SizedBox(height: 4),
                    Text(p['name'] as String? ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(ctx).textTheme.labelSmall),
                    Text('${p['photoCount'] ?? 0} photos', style: Theme.of(ctx).textTheme.labelSmall?.copyWith(color: Theme.of(ctx).colorScheme.outline)),
                  ]);
                },
              )),
          const SizedBox(height: 8),
        ])),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Widget _buildTimelineSidebar(List<PhotoModel> photos, ThemeData theme) {
    // Group photos by year-month
    final months = <String, int>{};
    for (final p in photos) {
      if (p.takenAt != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(p.takenAt!);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        months[key] = (months[key] ?? 0) + 1;
      }
    }
    final sortedMonths = months.keys.toList()..sort();
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return ListView.builder(
      itemCount: sortedMonths.length,
      itemBuilder: (_, i) {
        final parts = sortedMonths[i].split('-');
        final monthIdx = int.tryParse(parts[1]) ?? 1;
        return InkWell(
          onTap: () {
            // Scroll to first photo of this month
            final target = sortedMonths[i];
            final idx = photos.indexWhere((p) {
              if (p.takenAt == null) return false;
              final d = DateTime.fromMillisecondsSinceEpoch(p.takenAt!);
              return '${d.year}-${d.month.toString().padLeft(2, '0')}' == target;
            });
            if (idx >= 0) {
              // Visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Jumped to ${monthNames[monthIdx - 1]} ${parts[0]}'), duration: const Duration(seconds: 1)),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5))),
            child: Column(children: [
              Text(monthNames[monthIdx - 1], style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(parts[0].substring(2), style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.outline)),
            ]),
          ),
        );
      },
    );
  }
}
