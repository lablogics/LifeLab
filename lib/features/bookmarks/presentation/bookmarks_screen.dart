import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/bookmarks_providers.dart';
import '../data/models/bookmark_model.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookmarksProvider);
    final notifier = ref.read(bookmarksProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDialog(context, ref), child: const Icon(Icons.add)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.bookmarks.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bookmark_outline, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('No bookmarks yet')]))
              : ListView.builder(itemCount: state.bookmarks.length, itemBuilder: (ctx, i) {
                  final bm = state.bookmarks[i];
                  return ListTile(
                    leading: const Icon(Icons.bookmark, color: Colors.amber),
                    title: Text(bm.title.isNotEmpty ? bm.title : bm.url),
                    subtitle: Text(bm.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => notifier.deleteBookmark(bm.id)),
                    onTap: () => _launchUrl(bm.url),
                  );
                }),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Bookmark'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          ref.read(bookmarksProvider.notifier).createBookmark(BookmarkModel(id: '', url: urlCtrl.text, title: titleCtrl.text, description: descCtrl.text));
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
