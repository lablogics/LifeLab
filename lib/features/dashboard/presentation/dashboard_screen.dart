import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import '../../../app/command_palette.dart';
import '../../notes/presentation/quick_notes_widget.dart';

class DashboardStats {
  final int notes;
  final int projects;
  final int todos;
  final int bookmarks;
  final int contacts;
  final int photos;
  final int passwords;
  final int messages;
  final int? notesToday;
  final int? todosToday;
  final int? todosOverdue;

  const DashboardStats({
    this.notes = 0, this.projects = 0, this.todos = 0,
    this.bookmarks = 0, this.contacts = 0,
    this.photos = 0, this.passwords = 0, this.messages = 0,
    this.notesToday, this.todosToday, this.todosOverdue,
  });
}

class DashboardState {
  final DashboardStats? stats;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> recentNotes;
  final List<Map<String, dynamic>> todayTasks;
  final List<Map<String, dynamic>> birthdaysToday;
  final List<Map<String, dynamic>> importantContacts;

  const DashboardState({
    this.stats, this.isLoading = false, this.error,
    this.recentNotes = const [], this.todayTasks = const [],
    this.birthdaysToday = const [], this.importantContacts = const [],
  });
  DashboardState copyWith({
    DashboardStats? stats, bool? isLoading, String? error,
    List<Map<String, dynamic>>? recentNotes,
    List<Map<String, dynamic>>? todayTasks,
    List<Map<String, dynamic>>? birthdaysToday,
    List<Map<String, dynamic>>? importantContacts,
  }) {
    return DashboardState(
      stats: stats ?? this.stats, isLoading: isLoading ?? this.isLoading, error: error,
      recentNotes: recentNotes ?? this.recentNotes,
      todayTasks: todayTasks ?? this.todayTasks,
      birthdaysToday: birthdaysToday ?? this.birthdaysToday,
      importantContacts: importantContacts ?? this.importantContacts,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _api;
  DashboardNotifier(this._api) : super(const DashboardState(isLoading: true)) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get('${Endpoints.dashboard}/stats');
      final data = r.data as Map<String, dynamic>;
      state = state.copyWith(
        stats: DashboardStats(
          notes: (data['notes'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
          notesToday: (data['notes'] as Map<String, dynamic>?)?['today'] as int?,
          projects: (data['projects'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
          todos: (data['todos'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
          todosToday: (data['todos'] as Map<String, dynamic>?)?['today'] as int?,
          todosOverdue: (data['todos'] as Map<String, dynamic>?)?['overdue'] as int?,
          bookmarks: (data['bookmarks'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
          contacts: (data['contacts'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
          photos: (data['photos'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
          passwords: (data['passwords'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
          messages: (data['messages'] as Map<String, dynamic>?)?['total'] as int? ?? 0,
        ),
        isLoading: false,
      );
      // Load recent notes, today tasks, birthdays in parallel
      _loadRecentNotes();
      _loadTodayTasks();
      _loadBirthdays();
      _loadImportantContacts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadRecentNotes() async {
    try {
      final r = await _api.dio.dio.get(Endpoints.notes, queryParameters: {'limit': 5, 'sort': 'updated'});
      final list = (r.data as Map<String, dynamic>?)?['items'] as List? ?? (r.data as List? ?? []);
      final notes = list.take(5).map((e) => {
        'id': (e as Map<String, dynamic>)['id'] as String? ?? '',
        'title': e['title'] as String? ?? 'Untitled',
      }).toList();
      state = state.copyWith(recentNotes: notes);
    } catch (_) {}
  }

  Future<void> _loadTodayTasks() async {
    try {
      final r = await _api.dio.dio.get(Endpoints.todos, queryParameters: {'completed': false});
      final list = (r.data as Map<String, dynamic>?)?['items'] as List? ?? (r.data as List? ?? []);
      final tasks = list.take(5).map((e) => {
        'id': (e as Map<String, dynamic>)['id'] as String? ?? '',
        'title': e['title'] as String? ?? '',
      }).toList();
      state = state.copyWith(todayTasks: tasks);
    } catch (_) {}
  }

  Future<void> _loadBirthdays() async {
    try {
      final today = DateTime.now();
      final monthDay = '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final r = await _api.dio.dio.get(Endpoints.contacts);
      final list = (r.data as Map<String, dynamic>?)?['items'] as List? ?? (r.data as List? ?? []);
      final birthdays = list.where((e) {
        final bday = (e as Map<String, dynamic>)['birthday'] as String?;
        return bday != null && bday.length >= 5 && bday.substring(5) == monthDay;
      }).map((e) => {
        'id': (e as Map<String, dynamic>)['id'] as String? ?? '',
        'name': '${e['firstName'] ?? ''} ${e['lastName'] ?? ''}'.trim(),
      }).toList();
      state = state.copyWith(birthdaysToday: birthdays);
    } catch (_) {}
  }

  Future<void> _loadImportantContacts() async {
    try {
      final r = await _api.dio.dio.get(Endpoints.contacts);
      final list = (r.data as Map<String, dynamic>?)?['items'] as List? ?? (r.data as List? ?? []);
      final favs = list.where((e) {
        final m = e as Map<String, dynamic>;
        return m['isFavorite'] == true || m['isFavorite'] == 1;
      }).take(5).map((e) => {
        'id': (e as Map<String, dynamic>)['id'] as String? ?? '',
        'name': '${e['firstName'] ?? ''} ${e['lastName'] ?? ''}'.trim(),
        'email': e['email'] as String? ?? '',
      }).toList();
      state = state.copyWith(importantContacts: favs);
    } catch (_) {}
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(apiClientProvider));
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.terminal), tooltip: 'Command Palette',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandPalette()))),
          IconButton(icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardProvider.notifier).loadStats()),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          }),
        ],
      ),
      floatingActionButton: const QuickNotesWidget(),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).loadStats(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Welcome back!', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Here is your overview', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 24),
                  // Stats grid - row 1
                  Row(children: [
                    Expanded(child: _StatCard(title: 'Notes', count: state.stats?.notes ?? 0,
                      subtitle: state.stats?.notesToday != null ? '+${state.stats!.notesToday} today' : null,
                      icon: Icons.note, color: Colors.blue, onTap: () => context.go('/notes'))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'Todos', count: state.stats?.todos ?? 0,
                      subtitle: state.stats?.todosOverdue != null && state.stats!.todosOverdue! > 0
                          ? '${state.stats!.todosOverdue} overdue'
                          : state.stats?.todosToday != null ? '+${state.stats!.todosToday} today' : null,
                      icon: Icons.check_circle, color: Colors.green, onTap: () => context.go('/todos'))),
                  ]),
                  const SizedBox(height: 12),
                  // Stats grid - row 2
                  Row(children: [
                    Expanded(child: _StatCard(title: 'Projects', count: state.stats?.projects ?? 0,
                      icon: Icons.work, color: Colors.purple, onTap: () => context.go('/projects'))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'Photos', count: state.stats?.photos ?? 0,
                      icon: Icons.photo, color: Colors.pink, onTap: () => context.go('/photos'))),
                  ]),
                  const SizedBox(height: 12),
                  // Stats grid - row 3
                  Row(children: [
                    Expanded(child: _StatCard(title: 'Bookmarks', count: state.stats?.bookmarks ?? 0,
                      icon: Icons.bookmark, color: Colors.amber, onTap: () => context.go('/bookmarks'))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'Contacts', count: state.stats?.contacts ?? 0,
                      icon: Icons.contacts, color: Colors.teal, onTap: () => context.go('/contacts'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _StatCard(title: 'Passwords', count: state.stats?.passwords ?? 0,
                      icon: Icons.lock, color: Colors.red, onTap: () => context.go('/passwords'))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(title: 'Messages', count: state.stats?.messages ?? 0,
                      icon: Icons.message, color: Colors.indigo, onTap: () => context.go('/more'))),
                  ]),
                  const SizedBox(height: 24),

                  // Birthday reminders
                  if (state.birthdaysToday.isNotEmpty) ...[
                    Text('Birthdays Today', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...state.birthdaysToday.map((b) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.cake, color: Colors.pink),
                        title: Text(b['name'] as String? ?? ''),
                        onTap: () => context.push('/contacts'),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Recent notes
                  if (state.recentNotes.isNotEmpty) ...[
                    Text('Recent Notes', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...state.recentNotes.map((n) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.note, color: Colors.blue),
                        title: Text(n['title'] as String? ?? 'Untitled'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/notes/${n['id']}'),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Today's tasks
                  if (state.todayTasks.isNotEmpty) ...[
                    Text("Today's Tasks", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...state.todayTasks.map((t) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                        title: Text(t['title'] as String? ?? ''),
                        onTap: () => context.go('/todos'),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Smart suggestions
                  if (state.recentNotes.isNotEmpty || state.todayTasks.isNotEmpty) ...[
                    Text('Suggestions', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(child: ListTile(
                      leading: Icon(Icons.lightbulb, color: theme.colorScheme.tertiary),
                      title: const Text('Pull to refresh for latest data'),
                      subtitle: Text('${state.stats?.notes ?? 0} notes, ${state.stats?.todos ?? 0} todos'),
                    )),
                  ],

                  const SizedBox(height: 16),
                  // Quick Actions grid (2 rows x 4 cols)
                  Text('Quick Actions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(children: [
                    _QuickAction(Icons.note_add, 'New Note', Colors.blue, () => context.go('/notes')),
                    const SizedBox(width: 8),
                    _QuickAction(Icons.add_task, 'New Todo', Colors.green, () => context.go('/todos')),
                    const SizedBox(width: 8),
                    _QuickAction(Icons.camera_alt, 'Photo', Colors.purple, () => context.go('/photos')),
                    const SizedBox(width: 8),
                    _QuickAction(Icons.upload_file, 'Upload', Colors.orange, () => context.go('/drive')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _QuickAction(Icons.contacts, 'Contacts', Colors.teal, () => context.go('/contacts')),
                    const SizedBox(width: 8),
                    _QuickAction(Icons.bookmark, 'Bookmarks', Colors.amber, () => context.go('/bookmarks')),
                    const SizedBox(width: 8),
                    _QuickAction(Icons.lock, 'Passwords', Colors.red, () => context.go('/passwords')),
                    const SizedBox(width: 8),
                    _QuickAction(Icons.work, 'Projects', Colors.deepPurple, () => context.go('/projects')),
                  ]),
                  const SizedBox(height: 16),

                  // Important contacts widget
                  if (state.importantContacts.isNotEmpty) ...[
                    Text('Important Contacts', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...state.importantContacts.map((c) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text((c['name'] as String? ?? '?')[0].toUpperCase())),
                        title: Text(c['name'] as String? ?? ''),
                        subtitle: Text(c['email'] as String? ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/contacts'),
                      ),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title, required this.count, required this.icon,
    required this.color, required this.onTap, this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text('$count', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!, style: theme.textTheme.labelSmall?.copyWith(color: color)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
