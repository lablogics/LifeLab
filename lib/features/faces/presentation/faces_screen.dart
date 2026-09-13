import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/faces_providers.dart';

class FacesScreen extends ConsumerStatefulWidget {
  const FacesScreen({super.key});
  @override
  ConsumerState<FacesScreen> createState() => _FacesScreenState();
}

class _FacesScreenState extends ConsumerState<FacesScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(facesProvider.notifier).loadPeople();
      setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final faces = ref.watch(facesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(facesProvider.notifier).refresh()),
        ],
      ),
      body: faces.isLoading
          ? const Center(child: CircularProgressIndicator())
          : faces.people.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.face, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No people detected'),
                  const SizedBox(height: 8),
                  Text('Photos with faces will appear here', style: theme.textTheme.bodySmall),
                ]))
              : RefreshIndicator(
                  onRefresh: () => ref.read(facesProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16),
                    itemCount: faces.people.length,
                    itemBuilder: (ctx, i) {
                      final person = faces.people[i];
                      return GestureDetector(
                        onTap: () => _showPersonDetail(person),
                        child: Column(children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            child: person.faceUrl != null
                                ? ClipOval(child: Image.network(person.faceUrl!, fit: BoxFit.cover, width: 80, height: 80))
                                : Icon(Icons.face, size: 40, color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: 8),
                          Text(person.name, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (person.photoCount != null)
                            Text('${person.photoCount}', style: theme.textTheme.bodySmall),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }

  void _showPersonDetail(PersonModel person) {
    final ctrl = TextEditingController(text: person.name);
    showModalBottomSheet(context: context, builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.face, size: 50, color: Theme.of(ctx).colorScheme.outline),
        ),
        const SizedBox(height: 16),
        TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name'), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (person.photoCount != null) Text('${person.photoCount} photos'),
        const SizedBox(height: 16),
        FilledButton(onPressed: () {
          ref.read(facesProvider.notifier).renamePerson(person.id, ctrl.text.trim());
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ]),
    ));
  }
}
