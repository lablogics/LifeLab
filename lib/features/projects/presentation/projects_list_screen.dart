import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/projects_providers.dart';
import '../data/models/project_model.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});
  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(projectsProvider.notifier).loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.projects.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.work_outline, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No projects yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(projectsProvider.notifier).loadProjects(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.projects.length,
                        itemBuilder: (context, index) {
                          final project = state.projects[index];
                          return _ProjectCard(
                            project: project,
                            onTap: () => context.push('/projects/${project.id}'),
                            onDelete: () => _confirmDelete(context, project),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Project name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      ref.read(projectsProvider.notifier).createProject(name);
    }
  }

  void _confirmDelete(BuildContext context, ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('"${project.name}" and all its boards will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(projectsProvider.notifier).deleteProject(project.id);
    }
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ProjectCard({required this.project, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(project.updatedAt);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _parseColor(project.color),
                child: Text(project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(project.name, style: theme.textTheme.titleMedium),
                  if (project.description.isNotEmpty)
                    Text(project.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: project.status == 'active' ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(project.status, style: theme.textTheme.labelSmall?.copyWith(
                        color: project.status == 'active' ? Colors.green.shade700 : Colors.grey.shade700,
                      )),
                    ),
                    const SizedBox(width: 8),
                    Text('${date.day}/${date.month}/${date.year}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ]),
                ]),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String color) {
    if (color.startsWith('#') && color.length == 7) {
      return Color(int.parse('FF${color.substring(1)}', radix: 16));
    }
    return switch (color) {
      'red' => Colors.red, 'orange' => Colors.orange, 'yellow' => Colors.amber,
      'green' => Colors.green, 'blue' => Colors.blue, 'purple' => Colors.purple,
      'pink' => Colors.pink, _ => Colors.blue,
    };
  }
}
