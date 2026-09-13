import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'package:lifelab_core/auth/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/two_factor_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/notes/presentation/notes_list_screen.dart';
import '../features/notes/presentation/note_edit_screen.dart';
import '../features/todos/presentation/todos_list_screen.dart';
import '../features/projects/presentation/projects_list_screen.dart';
import '../features/projects/presentation/board_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import 'shell.dart';
import 'more_screen.dart';
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = auth.status == AuthStatus.authenticated;
      final needs2FA = auth.status == AuthStatus.needs2FA;
      final isLoginRoute = state.matchedLocation == '/login';
      final is2FARoute = state.matchedLocation == '/2fa';
      if (!isLoggedIn && !needs2FA && !isLoginRoute) return '/login';
      if (needs2FA && !is2FARoute) return '/2fa';
      if (isLoggedIn && (isLoginRoute || is2FARoute)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/2fa', builder: (context, state) => const TwoFactorScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/notes', builder: (context, state) => const NotesListScreen(),
            routes: [
              GoRoute(path: ':id', builder: (context, state) => NoteEditScreen(noteId: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/todos', builder: (context, state) => const TodosListScreen()),
          GoRoute(path: '/projects', builder: (context, state) => const ProjectsListScreen(),
            routes: [
              GoRoute(path: ':id', builder: (context, state) => BoardScreen(projectId: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
          GoRoute(path: '/more', builder: (context, state) => const MoreScreen()),
        ],
      ),
    ],
  );
});
