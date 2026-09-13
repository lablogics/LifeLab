import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/drive_providers.dart';
import '../../photos/data/photos_providers.dart';

class DriveScreen extends ConsumerStatefulWidget {
  const DriveScreen({super.key});
  @override
  ConsumerState<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends ConsumerState<DriveScreen> {
  String? _selectedStorageId;

  @override
  Widget build(BuildContext context) {
    final storages = ref.watch(storagesProvider);
    final drive = ref.watch(driveProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Drive'), leading: drive.path.isNotEmpty ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => ref.read(driveProvider.notifier).goBack()) : null, actions: [
        if (storages.storages.isNotEmpty)
          DropdownButton<String>(value: _selectedStorageId, hint: const Text('Storage'), items: storages.storages.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String? ?? 'Storage'))).toList(), onChanged: (v) { if (v != null) { setState(() => _selectedStorageId = v); ref.read(driveProvider.notifier).setStorage(v); } }),
      ]),
      body: _selectedStorageId == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 64, color: theme.colorScheme.outline), const SizedBox(height: 16), const Text('Select a storage to browse files')]))
          : drive.isLoading
              ? const Center(child: CircularProgressIndicator())
              : drive.items.isEmpty
                  ? Center(child: Text('Empty folder', style: theme.textTheme.bodyLarge))
                  : ListView.builder(itemCount: drive.items.length, itemBuilder: (ctx, i) {
                      final item = drive.items[i];
                      final isFolder = item.type == 'folder';
                      return ListTile(leading: Icon(isFolder ? Icons.folder : Icons.insert_drive_file, color: isFolder ? Colors.amber : theme.colorScheme.outline), title: Text(item.name), onTap: isFolder ? () => ref.read(driveProvider.notifier).loadFolder(item.id) : null);
                    }),
    );
  }
}
