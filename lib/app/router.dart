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
import '../features/search/presentation/search_screen.dart';
import '../features/passwords/presentation/passwords_screen.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/contacts/presentation/contacts_screen.dart';
import '../features/messages/presentation/messages_screen.dart';
import '../features/totp/presentation/totp_screen.dart';
import '../features/photos/presentation/photos_screen.dart';
import '../features/drive/presentation/drive_screen.dart';
import 'settings_screen.dart';
import '../features/mail/presentation/mail_screen.dart';
import '../features/voice/presentation/voice_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/backup/presentation/backup_screen.dart';
import '../features/videos/presentation/videos_screen.dart';
import '../features/videos/presentation/video_player_screen.dart';
import '../features/photos/presentation/photo_editor_screen.dart';import '../features/tags/presentation/tags_screen.dart';
import '../features/graph/presentation/graph_screen.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/versions/presentation/versions_screen.dart';
import '../features/attachments/presentation/attachments_screen.dart';
import '../features/albums/presentation/albums_screen.dart';
import '../features/faces/presentation/faces_screen.dart';

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
          GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          GoRoute(path: '/passwords', builder: (context, state) => const PasswordsScreen()),
          GoRoute(path: '/bookmarks', builder: (context, state) => const BookmarksScreen()),
          GoRoute(path: '/contacts', builder: (context, state) => const ContactsScreen()),
          GoRoute(path: '/contacts/:id/messages', builder: (context, state) => MessagesScreen(contactId: state.pathParameters['id']!, contactName: state.pathParameters['id']!)),
          GoRoute(path: '/totp', builder: (context, state) => const TotpScreen()),
          GoRoute(path: '/photos', builder: (context, state) => const PhotosScreen()),
          GoRoute(path: '/photos/albums', builder: (context, state) => const AlbumsScreen()),
          GoRoute(path: '/photos/faces', builder: (context, state) => const FacesScreen()),
          GoRoute(path: '/photos/:id/edit', builder: (context, state) => PhotoEditorScreen(imagePath: state.uri.queryParameters['url'] ?? '')),          GoRoute(path: '/videos', builder: (context, state) => const VideosScreen()),
          GoRoute(path: '/videos/:id/play', builder: (context, state) => VideoPlayerScreen(videoUrl: state.uri.queryParameters['url'] ?? '', title: state.uri.queryParameters['title'] ?? 'Video')),          GoRoute(path: '/drive', builder: (context, state) => const DriveScreen()),
          GoRoute(path: '/tags', builder: (context, state) => const TagsScreen()),
          GoRoute(path: '/graph', builder: (context, state) => const GraphScreen()),
          GoRoute(path: '/activity', builder: (context, state) => const ActivityScreen()),
          GoRoute(path: '/notes/:id/versions', builder: (context, state) => VersionsScreen(noteId: state.pathParameters['id']!, noteTitle: state.uri.queryParameters['title'] ?? 'Note')),
          GoRoute(path: '/notes/:id/attachments', builder: (context, state) => AttachmentsScreen(noteId: state.pathParameters['id']!)),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: '/mail', builder: (context, state) => const MailScreen()),
          GoRoute(path: '/voice', builder: (context, state) => const VoiceScreen()),
          GoRoute(path: '/finance', builder: (context, state) => const FinanceScreen()),
          GoRoute(path: '/backup', builder: (context, state) => const BackupScreen()),
        ],
      ),
    ],
  );
});
