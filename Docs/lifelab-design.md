# LifeLab Design Specification

> Flutter mobile client for the LifeOS API — full feature mirror with offline-first architecture.

## 1. Overview

LifeLab is a Flutter application targeting **Android + iOS** that consumes the LifeOS API. It mirrors all 28 LifeOS feature domains, including 25 server-backed features and 3 client-only features (Mail, Voice, Finance). The app uses an offline-first architecture with Isar as the local database and Dio for API communication, syncing changes bidirectionally when online.

### Confirmed Requirements

| Decision | Choice |
|----------|--------|
| Scope | Full mirror — all 28 modules |
| Platforms | Android + iOS only |
| State management | Riverpod |
| UI framework | Material 3 |
| Offline mode | Full offline with local DB + background sync |
| Local database | Isar |
| API client | Dio |
| Authentication | flutter_secure_storage + auto-refresh |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Architecture | Hybrid — core packages + feature folders |

---

## 2. Architecture

### Project Structure

```
LifeLab/
├── packages/
│   ├── lifelab_core/          # Shared infrastructure
│   │   ├── lib/
│   │   │   ├── api/           # Dio client, interceptors, endpoints
│   │   │   ├── db/            # Isar collections, repositories
│   │   │   ├── auth/          # Auth state, token storage
│   │   │   ├── sync/          # Offline queue, conflict resolution
│   │   │   ├── push/          # FCM setup, notification handlers
│   │   │   └── di/            # Riverpod providers
│   │   └── pubspec.yaml
│   │
│   └── lifelab_ui/            # Design system
│       ├── lib/
│       │   ├── theme/         # Material 3 theme, colors, typography
│       │   ├── widgets/       # Reusable components
│       │   └── constants/     # Spacing, sizes
│       └── pubspec.yaml
│
├── lib/
│   ├── features/
│   │   ├── auth/              # Login, register, 2FA setup
│   │   ├── dashboard/         # Stats overview
│   │   ├── notes/             # Notes, folders, tags, graph
│   │   ├── todos/             # Task management
│   │   ├── projects/          # Projects, boards, kanban
│   │   ├── calendar/          # Events
│   │   ├── passwords/         # Password vault
│   │   ├── bookmarks/         # URL bookmarks
│   │   ├── contacts/          # Contact management
│   │   ├── messages/          # Messaging
│   │   ├── totp/              # Authenticator
│   │   ├── drive/             # File browser
│   │   ├── photos/            # Gallery + face detection
│   │   ├── videos/            # Video player
│   │   ├── mail/              # Email client (local only)
│   │   ├── voice/             # Voice notes (local only)
│   │   ├── finance/           # Finance tracker (local only)
│   │   ├── settings/          # Profile, 2FA, sessions, backup
│   │   └── search/            # Global search
│   │
│   ├── app/
│   │   ├── app.dart           # MaterialApp config
│   │   ├── router.dart        # GoRouter setup
│   │   └── shell.dart         # Navigation shell
│   │
│   └── main.dart
│
└── pubspec.yaml
```

### Feature Module Pattern

Each feature follows a consistent internal structure:

```
lib/features/<feature>/
├── data/
│   ├── <feature>_repository.dart         # API + Isar operations
│   ├── <feature>_remote_datasource.dart  # Dio calls
│   └── <feature>_local_datasource.dart   # Isar operations
├── domain/
│   ├── <feature>_model.dart              # Business model
│   └── <feature>_entity.dart             # Isar collection
├── presentation/
│   ├── <feature>_screen.dart             # Main screen
│   ├── <feature>_detail_screen.dart      # Detail/edit screen
│   ├── <feature>_provider.dart           # Riverpod state
│   └── widgets/                          # Feature-specific widgets
└── di/
    └── <feature>_providers.dart          # Dependency injection
```

---

## 3. Data Layer

### API Client (Dio)

```
packages/lifelab_core/lib/api/
├── dio_client.dart           # Base Dio instance with interceptors
├── interceptors/
│   ├── auth_interceptor.dart     # Auto-attach session cookie/token
│   ├── refresh_interceptor.dart  # Auto-refresh on 401
│   └── error_interceptor.dart    # Transform errors
├── endpoints.dart            # All 28 API endpoint constants
└── api_client.dart           # Typed methods per domain
```

- Cookie-based auth matching LifeOS session cookies
- Auto-retry on 401 with token refresh
- Request/response logging in debug mode
- Timeout handling and connectivity checks

### Local Database (Isar)

```
packages/lifelab_core/lib/db/collections/
├── note_collection.dart
├── todo_collection.dart
├── project_collection.dart
├── contact_collection.dart
├── password_collection.dart
├── bookmark_collection.dart
├── message_collection.dart
├── calendar_event_collection.dart
├── drive_file_collection.dart
├── photo_collection.dart
├── video_collection.dart
├── mail_collection.dart           # Local-only
├── voice_note_collection.dart     # Local-only
├── finance_entry_collection.dart  # Local-only
└── sync_meta_collection.dart      # Tracks sync state per entity
```

Each collection mirrors the LifeOS DB schema with additional sync fields:

```dart
@collection
class Note {
  Id id = Isar.autoIncrement;
  String remoteId;           // UUID from LifeOS
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? syncedAt;        // Last sync timestamp
  SyncStatus syncStatus;     // pending, synced, conflict
}
```

### Repository Pattern

```dart
abstract class Repository<Remote, Local> {
  // Read from local first
  Future<List<Local>> getAll();
  Future<Local> getById(String id);

  // Write to local + queue sync
  Future<void> create(Local item);
  Future<void> update(Local item);
  Future<void> delete(String id);

  // Sync operations
  Future<void> syncFromRemote();
  Future<void> pushPendingChanges();
}
```

### Sync Strategy

1. **On app start:** Check connectivity, pull all changes since last sync
2. **On mutation:** Write to Isar immediately, mark as `syncStatus: pending`
3. **Background sync:** Every 5 minutes (or on connectivity change), push pending changes
4. **Conflict resolution:** Server wins (can evolve to merge later)
5. **Offline queue:** Store failed requests, retry with exponential backoff

**Client-only features (Mail/Voice/Finance):**
- No sync, Isar is the source of truth
- Optional export/backup via `/api/export/backup` endpoint

---

## 4. Authentication & Security

### Auth Flow

```
packages/lifelab_core/lib/auth/
├── auth_repository.dart      # Login, register, logout, 2FA
├── auth_state.dart           # AuthState enum + user state
├── auth_provider.dart        # Riverpod StateNotifier
├── token_storage.dart        # flutter_secure_storage wrapper
└── biometric_auth.dart       # Optional biometric unlock
```

### Authentication States

```dart
enum AuthStatus {
  initial,         // App just started
  unauthenticated, // No session
  authenticating,  // Login/register in progress
  needs2FA,        // 2FA code required
  authenticated,   // Logged in
  expired,         // Session expired, refreshing
}
```

### Login Flow

1. User enters email/password → POST `/api/auth/login`
2. Server returns session cookie + checks 2FA status
3. If 2FA enabled → show TOTP input screen
4. User enters 6-digit code → POST `/api/2fa/verify`
5. Success → store session in secure storage, navigate to dashboard
6. On app restart → auto-login from secure storage, validate session

### Token Management

```dart
class TokenStorage {
  final FlutterSecureStorage _storage;

  Future<void> saveSession(String sessionToken);
  Future<String?> getSession();
  Future<void> clearSession();

  // Optional biometric protection
  Future<void> enableBiometricUnlock();
  Future<bool> authenticateWithBiometric();
}
```

### Security Features

- **Secure storage:** `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android)
- **Session management:** Auto-refresh on 401, track active sessions via `/api/sessions`, revoke from settings
- **2FA support:** Enable/disable from settings, generate backup codes, TOTP setup with QR code
- **Biometric unlock:** Optional fingerprint/face ID after initial login, fallback to password, configurable timeout

### API Security Interceptors

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.getSession();
    if (token != null) {
      options.headers['Cookie'] = 'session=$token';
    }
    handler.next(options);
  }
}

class RefreshInterceptor extends Interceptor {
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      authRepository.refreshSession().then((success) {
        if (success) handler.resolve(err.requestOptions); // Retry
        else handler.next(err); // Force logout
      });
    } else {
      handler.next(err);
    }
  }
}
```

---

## 5. Push Notifications

```
packages/lifelab_core/lib/push/
├── push_service.dart         # FCM initialization + token management
├── notification_handler.dart # Handle incoming notifications
└── push_provider.dart        # Riverpod provider
```

### Push Flow

1. On app start → initialize Firebase, get FCM token
2. Subscribe → POST `/api/push/subscribe` with token + keys
3. On notification received → show local notification or handle silently
4. On token refresh → update subscription on server

### Notification Types

- New message received
- Task assigned/due
- Security alert (new login, 2FA)

---

## 6. Navigation (GoRouter)

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = auth.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => DashboardScreen()),
          GoRoute(path: '/notes', builder: (_, __) => NotesScreen()),
          GoRoute(path: '/notes/:id', builder: (_, state) => NoteDetailScreen(id: state.pathParameters['id']!)),
          GoRoute(path: '/todos', builder: (_, __) => TodosScreen()),
          GoRoute(path: '/projects', builder: (_, __) => ProjectsScreen()),
          GoRoute(path: '/calendar', builder: (_, __) => CalendarScreen()),
          GoRoute(path: '/passwords', builder: (_, __) => PasswordsScreen()),
          GoRoute(path: '/bookmarks', builder: (_, __) => BookmarksScreen()),
          GoRoute(path: '/contacts', builder: (_, __) => ContactsScreen()),
          GoRoute(path: '/messages', builder: (_, __) => MessagesScreen()),
          GoRoute(path: '/authenticator', builder: (_, __) => AuthenticatorScreen()),
          GoRoute(path: '/drive', builder: (_, __) => DriveScreen()),
          GoRoute(path: '/photos', builder: (_, __) => PhotosScreen()),
          GoRoute(path: '/videos', builder: (_, __) => VideosScreen()),
          GoRoute(path: '/mail', builder: (_, __) => MailScreen()),
          GoRoute(path: '/voice', builder: (_, __) => VoiceScreen()),
          GoRoute(path: '/finance', builder: (_, __) => FinanceScreen()),
          GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
          GoRoute(path: '/search', builder: (_, __) => SearchScreen()),
        ],
      ),
    ],
  );
});
```

---

## 7. Feature Inventory

### Server-Backed Features (25)

| Feature | API Routes | Key Capabilities |
|---------|-----------|------------------|
| Auth | `/api/auth`, `/api/2fa`, `/api/sessions` | Login, register, 2FA, session management |
| Dashboard | `/api/dashboard`, `/api/activity` | Stats, recent activity |
| Notes | `/api/notes`, `/api/folders`, `/api/tags` | Rich text, wikilinks, graph view, templates, daily notes |
| Todos | `/api/todos` | Task management, due dates |
| Projects | `/api/projects`, `/api/boards` | Kanban boards, drag-drop |
| Calendar | `/api/calendar` | Events, date filtering |
| Passwords | `/api/passwords` | Encrypted vault |
| Bookmarks | `/api/bookmarks` | URL bookmarks |
| Contacts | `/api/contacts` | Contact management |
| Messages | `/api/messages` | Conversations |
| TOTP | `/api/totp` | Authenticator codes |
| Drive | `/api/drive`, `/api/storages` | File browser, uploads |
| Photos | `/api/photos`, `/api/faces` | Gallery, face detection |
| Videos | `/api/videos` | Video player |
| Search | `/api/search` | Global search |
| Settings | `/api/auth/profile`, `/api/export` | Profile, backup/restore |
| Versions | `/api/versions` | Note version history |
| Attachments | `/api/attachments` | File attachments on notes |
| Faces | `/api/faces` | Face detection and clustering |
| Storages | `/api/storages` | External storage backends |
| Push | `/api/push` | Push notification subscriptions |
| Export | `/api/export` | Full backup/restore |
| Activity | `/api/activity` | Activity log feed |

### Client-Only Features (3)

| Feature | Storage | Key Capabilities |
|---------|---------|------------------|
| Mail | Isar only | Email client, local folders |
| Voice | Isar only | Voice notes, recording |
| Finance | Isar only | Budget tracking, expenses |

---

## 8. Implementation Phases

### Phase 1: Foundation (Week 1-2)

- Scaffold Flutter app with packages structure
- Set up core infrastructure (API client, Isar DB, auth)
- Implement login/register with 2FA support
- Build navigation shell with bottom nav
- Material 3 theme setup

### Phase 2: Core Productivity (Week 3-5)

- Notes: list, detail, create, edit, delete, folders, tags, rich text editor
- Todos: list, create, toggle, delete, due dates
- Projects: list, detail, boards, columns, cards, drag-drop Kanban
- Calendar: month view, events, create/edit
- Dashboard: stats cards, recent activity
- Global search across notes/todos/projects
- Offline sync for all above

### Phase 3: Security & Media (Week 6-8)

- Passwords: vault UI, encryption/decryption
- Bookmarks: list, create, categorize
- Contacts: list, detail, create/edit
- Messages: conversation list, chat view
- TOTP authenticator: display codes, add accounts
- Photos: gallery grid, viewer, face detection
- Videos: video player with controls
- Drive: file browser, upload/download
- Push notifications: FCM setup, subscribe/unsubscribe
- Settings: profile edit, change password, session management

### Phase 4: Client-Only Features (Week 9-10)

- Mail: local email client with folders
- Voice: voice note recorder + player
- Finance: budget tracker, expense categories
- Backup: export all data to JSON
- Restore: import from JSON backup

### Phase 5: Polish & Launch (Week 11-12)

- Unit tests for repositories and providers (70% coverage target)
- Widget tests for key screens
- Integration tests for auth flow
- Performance profiling (60fps, memory)
- Offline sync stress testing
- Error handling and edge cases
- App icons and splash screen
- README, screenshots, descriptions
- Build release APK/AAB and IPA

---

## 9. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^13.0.0

  # API
  dio: ^5.4.0

  # Local database
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1

  # Security
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.1.8

  # Push notifications
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0

  # UI
  flutter_quill: ^9.2.0       # Rich text editor
  fl_chart: ^0.66.0           # Charts for dashboard
  cached_network_image: ^3.3.0

  # Utils
  intl: ^0.19.0
  uuid: ^4.3.0
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  isar_generator: ^3.1.0+1
  json_serializable: ^6.7.0
  mocktail: ^1.0.0
```

---

## 10. Testing Strategy

### Unit Tests (70% coverage target)

Repository and provider logic tests with mocked datasources.

### Widget Tests

Key screen rendering and interaction tests with mocked providers.

### Integration Tests

Full auth flow (login → 2FA → dashboard), offline sync flow, and backup/restore flow.
