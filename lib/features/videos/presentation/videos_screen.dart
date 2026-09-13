import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/videos_providers.dart';

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});
  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  @override
  void initState() { super.initState(); Future.microtask(() => ref.read(videosProvider.notifier).loadVideos()); }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videosProvider);
    final theme = Theme.of(context);
    final videos = state.filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search videos...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
              onChanged: (v) => ref.read(videosProvider.notifier).setSearch(v),
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(videosProvider.notifier).refresh()),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.videocam_off, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), Text('No videos', style: theme.textTheme.bodyLarge)]))
              : RefreshIndicator(
                  onRefresh: () => ref.read(videosProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (ctx, i) {
                      final v = videos[i];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer, child: Icon(Icons.play_circle_fill, color: theme.colorScheme.primary)),
                        title: Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text([_formatSize(v.size), if (v.width != null) '${v.width}x${v.height}'].where((s) => s.isNotEmpty).join(' · ')),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(v)),
                      );
                    },
                  ),
                ),
    );
  }

  void _confirmDelete(VideoModel v) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Video'),
      content: Text('Delete "${v.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton.tonal(onPressed: () { Navigator.pop(ctx); ref.read(videosProvider.notifier).deleteVideo(v.id); }, child: const Text('Delete')),
      ],
    ));
  }
}
