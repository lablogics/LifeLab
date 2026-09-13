import '../../../core/sync/sync_providers.dart';
import '../../../core/sync/sync_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'projects_remote_datasource.dart';
import 'projects_repository.dart';
import 'models/project_model.dart';

final projectsRemoteDataSourceProvider = Provider<ProjectsRemoteDataSource>((ref) {
  return ProjectsRemoteDataSource(ref.watch(apiClientProvider));
});

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(projectsRemoteDataSourceProvider));
});

class ProjectsState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final String? error;
  const ProjectsState({this.projects = const [], this.isLoading = false, this.error});
  ProjectsState copyWith({List<ProjectModel>? projects, bool? isLoading, String? error}) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final SyncEngine? _sync;
  final ProjectsRepository _repo;
  ProjectsNotifier(this._repo, [this._sync]) : super(const ProjectsState());

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true);
    try {
      final projects = await _repo.getProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createProject(String name, {String? description}) async {
    try {
      await _repo.createProject(name, description: description);
      _sync?.enqueueCreate('project', name, {'name': name, 'description': description ?? ''});
      await loadProjects();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _repo.deleteProject(id);
      _sync?.enqueueDelete('project', id);
      state = state.copyWith(projects: state.projects.where((p) => p.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier(ref.watch(projectsRepositoryProvider), ref.watch(syncEngineProvider));
});
