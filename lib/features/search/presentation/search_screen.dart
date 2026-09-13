import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search notes, todos, projects...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchProvider.notifier).clear();
                    },
                  )
                : null,
          ),
          onChanged: _onQueryChanged,
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.query.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('Search across all your data', style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : state.results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('No results for "${state.query}"', style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            if (state.notes.isNotEmpty) ...[
                              _SectionHeader(title: 'Notes', count: state.notes.length),
                              ...state.notes.map((r) => _NoteTile(result: r)),
                            ],
                            if (state.todos.isNotEmpty) ...[
                              _SectionHeader(title: 'Todos', count: state.todos.length),
                              ...state.todos.map((r) => _TodoTile(result: r)),
                            ],
                            if (state.projects.isNotEmpty) ...[
                              _SectionHeader(title: 'Projects', count: state.projects.length),
                              ...state.projects.map((r) => _ProjectTile(result: r)),
                            ],
                          ],
                        ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('($count)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final SearchResult result;
  const _NoteTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.note, color: Colors.blue),
      title: Text(result.title),
      subtitle: result.subtitle != null && result.subtitle!.isNotEmpty
          ? Text(result.subtitle!.length > 100 ? '${result.subtitle!.substring(0, 100)}...' : result.subtitle!)
          : null,
      onTap: () => context.push('/notes/${result.id}'),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final SearchResult result;
  const _TodoTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        result.completed == true ? Icons.check_circle : Icons.radio_button_unchecked,
        color: result.completed == true ? Colors.green : Colors.orange,
      ),
      title: Text(
        result.title,
        style: TextStyle(decoration: result.completed == true ? TextDecoration.lineThrough : null),
      ),
      onTap: () => context.push('/todos'),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final SearchResult result;
  const _ProjectTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.work_outline, color: Colors.purple),
      title: Text(result.title),
      subtitle: result.subtitle != null && result.subtitle!.isNotEmpty
          ? Text(result.subtitle!.length > 100 ? '${result.subtitle!.substring(0, 100)}...' : result.subtitle!)
          : null,
      onTap: () => context.push('/projects/${result.id}'),
    );
  }
}
