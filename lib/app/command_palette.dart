import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  static const _routes = <_PaletteItem>[
    _PaletteItem('Dashboard', Icons.dashboard, '/dashboard'),
    _PaletteItem('Notes', Icons.note, '/notes'),
    _PaletteItem('Todos', Icons.check_circle, '/todos'),
    _PaletteItem('Projects', Icons.work, '/projects'),
    _PaletteItem('Calendar', Icons.calendar_month, '/calendar'),
    _PaletteItem('Photos', Icons.photo, '/photos'),
    _PaletteItem('Drive', Icons.folder, '/drive'),
    _PaletteItem('Bookmarks', Icons.bookmark, '/bookmarks'),
    _PaletteItem('Contacts', Icons.contacts, '/contacts'),
    _PaletteItem('Passwords', Icons.lock, '/passwords'),
    _PaletteItem('TOTP Authenticator', Icons.timer, '/totp'),
    _PaletteItem('Search', Icons.search, '/search'),
    _PaletteItem('Settings', Icons.settings, '/settings'),
    _PaletteItem('Mail', Icons.mail, '/mail'),
    _PaletteItem('Voice Notes', Icons.mic, '/voice'),
    _PaletteItem('Finance', Icons.account_balance, '/finance'),
    _PaletteItem('Videos', Icons.videocam, '/videos'),
    _PaletteItem('Knowledge Graph', Icons.hub, '/graph'),
    _PaletteItem('Tags', Icons.label, '/tags'),
    _PaletteItem('Activity', Icons.history, '/activity'),
  ];

  List<_PaletteItem> get _filtered {
    if (_query.isEmpty) return _routes;
    final q = _query.toLowerCase();
    return _routes.where((r) => r.label.toLowerCase().contains(q)).toList();
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
                constraints:
                    const BoxConstraints(maxHeight: 500, maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Type a command or search...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                        onSubmitted: (_) {
                          if (items.isNotEmpty) {
                            _navigate(items.first.route);
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No results for "$_query"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            return ListTile(
                              leading: Icon(item.icon,
                                  color: theme.colorScheme.outline),
                              title: Text(item.label),
                              trailing: const Icon(Icons.arrow_forward,
                                  size: 16),
                              onTap: () => _navigate(item.route),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Tap to navigate',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
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

class _PaletteItem {
  final String label;
  final IconData icon;
  final String route;
  const _PaletteItem(this.label, this.icon, this.route);
}
