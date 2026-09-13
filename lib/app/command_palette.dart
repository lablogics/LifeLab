import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

/// Result item from API search or route navigation
sealed class _PaletteItem {
  const _PaletteItem();
}

class _RouteItem extends _PaletteItem {
  final String label;
  final IconData icon;
  final String route;
  const _RouteItem(this.label, this.icon, this.route);
}

class _SearchResultItem extends _PaletteItem {
  final String label;
  final IconData icon;
  final String route;
  final String? snippet;
  const _SearchResultItem(this.label, this.icon, this.route, {this.snippet});
}

/// Global command palette overlay for quick search and navigation
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  List<_SearchResultItem> _searchResults = [];
  Timer? _debounce;
  bool _searching = false;

  static const _routes = <_RouteItem>[
    _RouteItem('Dashboard', Icons.dashboard, '/dashboard'),
    _RouteItem('Notes', Icons.note, '/notes'),
    _RouteItem('Todos', Icons.check_circle, '/todos'),
    _RouteItem('Projects', Icons.work, '/projects'),
    _RouteItem('Calendar', Icons.calendar_month, '/calendar'),
    _RouteItem('Photos', Icons.photo, '/photos'),
    _RouteItem('Drive', Icons.folder, '/drive'),
    _RouteItem('Bookmarks', Icons.bookmark, '/bookmarks'),
    _RouteItem('Contacts', Icons.contacts, '/contacts'),
    _RouteItem('Passwords', Icons.lock, '/passwords'),
    _RouteItem('TOTP Authenticator', Icons.timer, '/totp'),
    _RouteItem('Search', Icons.search, '/search'),
    _RouteItem('Settings', Icons.settings, '/settings'),
    _RouteItem('Mail', Icons.mail, '/mail'),
    _RouteItem('Voice Notes', Icons.mic, '/voice'),
    _RouteItem('Finance', Icons.account_balance, '/finance'),
    _RouteItem('Videos', Icons.videocam, '/videos'),
    _RouteItem('Knowledge Graph', Icons.hub, '/graph'),
    _RouteItem('Tags', Icons.label, '/tags'),
    _RouteItem('Activity', Icons.history, '/activity'),
  ];

  List<_PaletteItem> get _filtered {
    if (_query.isEmpty) return _routes;
    final q = _query.toLowerCase();
    final routeMatches = _routes.where((r) => r.label.toLowerCase().contains(q)).toList();
    // Combine route matches with search results
    return [...routeMatches, ..._searchResults];
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _performSearch(value));
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get(
        Endpoints.search,
        queryParameters: {'q': query},
      );
      final data = r.data as Map<String, dynamic>;
      final results = <_SearchResultItem>[];

      // Parse notes
      final notes = data['notes'] as List? ?? [];
      for (final n in notes.take(5)) {
        final note = n as Map<String, dynamic>;
        results.add(_SearchResultItem(
          note['title'] as String? ?? 'Untitled',
          Icons.note,
          '/notes/${note['id']}',
          snippet: (note['contentText'] as String?)?.substring(0, (note['contentText'] as String?)?.length.clamp(0, 80) ?? 0),
        ));
      }

      // Parse todos
      final todos = data['todos'] as List? ?? [];
      for (final t in todos.take(5)) {
        final todo = t as Map<String, dynamic>;
        results.add(_SearchResultItem(
          todo['title'] as String? ?? 'Untitled',
          Icons.check_circle,
          '/todos',
          snippet: (todo['completed'] as bool? ?? false) ? 'Completed' : 'Pending',
        ));
      }

      // Parse projects
      final projects = data['projects'] as List? ?? [];
      for (final p in projects.take(5)) {
        final proj = p as Map<String, dynamic>;
        results.add(_SearchResultItem(
          proj['name'] as String? ?? 'Untitled',
          Icons.work,
          '/projects',
          snippet: proj['description'] as String?,
        ));
      }

      if (mounted) setState(() { _searchResults = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _navigate(String path) {
    Navigator.pop(context);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search notes, todos, projects...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searching)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: _onQueryChanged,
                        onSubmitted: (_) {
                          if (items.isNotEmpty) _navigate(items.first is _RouteItem ? (items.first as _RouteItem).route : (items.first as _SearchResultItem).route);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    if (_query.isNotEmpty && items.isEmpty && !_searching)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No results for "$_query"',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            if (item is _RouteItem) {
                              return ListTile(
                                leading: Icon(item.icon, color: theme.colorScheme.outline),
                                title: Text(item.label),
                                trailing: const Icon(Icons.arrow_forward, size: 16),
                                onTap: () => _navigate(item.route),
                              );
                            } else {
                              final s = item as _SearchResultItem;
                              return ListTile(
                                leading: Icon(s.icon, color: theme.colorScheme.primary),
                                title: Text(s.label),
                                subtitle: s.snippet != null ? Text(s.snippet!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                                trailing: const Icon(Icons.arrow_forward, size: 16),
                                onTap: () => _navigate(s.route),
                              );
                            }
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _query.isEmpty ? 'Type to search across all content' : 'Tap to navigate',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
