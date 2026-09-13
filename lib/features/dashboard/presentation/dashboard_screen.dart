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
  final int? notesToday;
  final int? todosToday;
  final int? todosOverdue;

  const DashboardStats({
    this.notes = 0, this.projects = 0, this.todos = 0,
    this.bookmarks = 0, this.contacts = 0,
    this.notesToday, this.todosToday, this.todosOverdue,
  });
}

class DashboardState {
  final DashboardStats? stats;
  final bool isLoading;
  final String? error;
  const DashboardState({this.stats, this.isLoading = false, this.error});
  DashboardState copyWith({DashboardStats? stats, bool? isLoading, String? error}) {
    return DashboardState(stats: stats ?? this.stats, isLoading: isLoading ?? this.isLoading, error: error);
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
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
          IconButton(
            icon: const Icon(Icons.terminal), tooltip: 'Command Palette', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandPalette())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardProvider.notifier).loadStats(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
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
                  // Stats grid
                  Row(
                    children: [
                      Expanded(child: _StatCard(
                        title: 'Notes',
                        count: state.stats?.notes ?? 0,
                        subtitle: state.stats?.notesToday != null ? '+${state.stats!.notesToday} today' : null,
                        icon: Icons.note,
                        color: Colors.blue,
                        onTap: () => context.go('/notes'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        title: 'Todos',
                        count: state.stats?.todos ?? 0,
                        subtitle: state.stats?.todosOverdue != null && state.stats!.todosOverdue! > 0
                            ? '${state.stats!.todosOverdue} overdue'
                            : state.stats?.todosToday != null ? '+${state.stats!.todosToday} today' : null,
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onTap: () => context.go('/todos'),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(
                        title: 'Projects', count: state.stats?.projects ?? 0, icon: Icons.work, color: Colors.purple,
                        onTap: () => context.go('/projects'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        title: 'Calendar', count: 0, icon: Icons.calendar_month, color: Colors.orange,
                        onTap: () => context.go('/calendar'),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(
                        title: 'Bookmarks', count: state.stats?.bookmarks ?? 0,
                        icon: Icons.bookmark, color: Colors.amber, onTap: () {},
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        title: 'Contacts', count: state.stats?.contacts ?? 0,
                        icon: Icons.contacts, color: Colors.teal, onTap: () {},
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Quick Actions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuickAction(Icons.note_add, 'New Note', Colors.blue, () => context.go('/notes')),
                      const SizedBox(width: 8),
                      _QuickAction(Icons.add_task, 'New Todo', Colors.green, () => context.go('/todos')),
                      const SizedBox(width: 8),
                      _QuickAction(Icons.camera_alt, 'Photo', Colors.purple, () => context.go('/photos')),
                      const SizedBox(width: 8),
                      _QuickAction(Icons.upload_file, 'Upload', Colors.orange, () => context.go('/drive')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Recent Activity', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline, color: theme.colorScheme.outline),
                      title: const Text('Pull to refresh for latest data'),
                      subtitle: Text('${state.stats?.notes ?? 0} notes, ${state.stats?.todos ?? 0} todos'),
                    ),
                  ),
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
