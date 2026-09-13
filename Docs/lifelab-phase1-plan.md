# LifeLab Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the LifeLab Flutter app with core infrastructure (API client, Isar DB, auth flow) and navigation shell, delivering a working login → 2FA → dashboard flow.

**Architecture:** Hybrid structure with `packages/lifelab_core` (API, DB, auth, sync, push, DI) and `packages/lifelab_ui` (Material 3 theme, widgets), plus `lib/features/<domain>` for 28 feature folders. Phase 1 focuses on auth, dashboard, and core infrastructure only.

**Tech Stack:** Flutter 3.x, Riverpod, Dio, Isar, GoRouter, flutter_secure_storage, Material 3

---

## Task 1: Scaffold Flutter Project Structure

**Files:**
- Create: `pubspec.yaml` (root)
- Create: `packages/lifelab_core/pubspec.yaml`
- Create: `packages/lifelab_ui/pubspec.yaml`

- [ ] **Step 1: Create root Flutter project**

Run:
```bash
cd /Users/abdeljalil/Projects/Logicielab/LifeLab
flutter create --project-name lifelab --org com.logicielab .
```

Expected: Flutter project scaffolded with `lib/main.dart`, `pubspec.yaml`, `android/`, `ios/`

- [ ] **Step 2: Create lifelab_core package**

Run:
```bash
cd packages
flutter create --template=package --project-name=lifelab_core lifelab_core
```

Expected: `packages/lifelab_core/` with `lib/lifelab_core.dart`, `pubspec.yaml`

- [ ] **Step 3: Create lifelab_ui package**

Run:
```bash
flutter create --template=package --project-name=lifelab_ui lifelab_ui
```

Expected: `packages/lifelab_ui/` with `lib/lifelab_ui.dart`, `pubspec.yaml`

- [ ] **Step 4: Add dependencies to root pubspec.yaml**

Edit `pubspec.yaml`:
```yaml
name: lifelab
description: Flutter mobile client for LifeOS API
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Local packages
  lifelab_core:
    path: packages/lifelab_core
  lifelab_ui:
    path: packages/lifelab_ui
  
  # State management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^13.0.0
  
  # UI
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 5: Add dependencies to lifelab_core/pubspec.yaml**

Edit `packages/lifelab_core/pubspec.yaml`:
```yaml
name: lifelab_core
description: Core infrastructure for LifeLab (API, DB, auth, sync)
version: 0.0.1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # API
  dio: ^5.4.0
  
  # Local database
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  
  # Security
  flutter_secure_storage: ^9.0.0
  
  # Utils
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

- [ ] **Step 6: Add dependencies to lifelab_ui/pubspec.yaml**

Edit `packages/lifelab_ui/pubspec.yaml`:
```yaml
name: lifelab_ui
description: Design system and reusable widgets for LifeLab
version: 0.0.1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
```

- [ ] **Step 7: Install dependencies**

Run:
```bash
cd /Users/abdeljalil/Projects/Logicielab/LifeLab
flutter pub get
cd packages/lifelab_core && flutter pub get
cd ../lifelab_ui && flutter pub get
cd ../..
```

Expected: All dependencies resolved without errors

- [ ] **Step 8: Commit scaffold**

Run:
```bash
git init
git add .
git commit -m "feat: scaffold LifeLab Flutter project with core packages"
```

Expected: Initial commit created

---

## Task 2: Set Up Material 3 Theme

**Files:**
- Create: `packages/lifelab_ui/lib/theme/app_theme.dart`
- Create: `packages/lifelab_ui/lib/theme/app_colors.dart`
- Create: `packages/lifelab_ui/lib/theme/app_typography.dart`
- Test: `packages/lifelab_ui/test/theme/app_theme_test.dart`

- [ ] **Step 1: Write failing test for theme**

Create `packages/lifelab_ui/test/theme/app_theme_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_ui/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
    });

    test('light theme has light brightness', () {
      final theme = AppTheme.light();
      expect(theme.brightness, equals(Brightness.light));
    });

    test('dark theme has dark brightness', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, equals(Brightness.dark));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd packages/lifelab_ui
flutter test test/theme/app_theme_test.dart
```

Expected: FAIL with "AppTheme not defined"

- [ ] **Step 3: Implement AppColors**

Create `packages/lifelab_ui/lib/theme/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // Secondary
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Tertiary
  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31111D);

  // Error
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  // Surface
  static const Color surface = Color(0xFFFFFBFE);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Outline
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // Background
  static const Color background = Color(0xFFFFFBFE);
  static const Color onBackground = Color(0xFF1C1B1F);
}
```

- [ ] **Step 4: Implement AppTypography**

Create `packages/lifelab_ui/lib/theme/app_typography.dart`:
```dart
import 'package:flutter/material.dart';

class AppTypography {
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );
}
```

- [ ] **Step 5: Implement AppTheme**

Create `packages/lifelab_ui/lib/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: AppTypography.lightTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: AppTypography.darkTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Export theme from lifelab_ui**

Edit `packages/lifelab_ui/lib/lifelab_ui.dart`:
```dart
library lifelab_ui;

export 'theme/app_theme.dart';
export 'theme/app_colors.dart';
export 'theme/app_typography.dart';
```

- [ ] **Step 7: Run test to verify it passes**

Run:
```bash
cd packages/lifelab_ui
flutter test test/theme/app_theme_test.dart
```

Expected: PASS

- [ ] **Step 8: Commit theme**

Run:
```bash
git add packages/lifelab_ui/
git commit -m "feat: add Material 3 theme with light/dark modes"
```

Expected: Theme committed

---

## Task 3: Set Up Isar Database

**Files:**
- Create: `packages/lifelab_core/lib/db/isar_database.dart`
- Create: `packages/lifelab_core/lib/db/collections/user_collection.dart`
- Create: `packages/lifelab_core/lib/db/collections/sync_meta_collection.dart`
- Test: `packages/lifelab_core/test/db/isar_database_test.dart`

- [ ] **Step 1: Write failing test for database initialization**

Create `packages/lifelab_core/test/db/isar_database_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_core/db/isar_database.dart';

void main() {
  group('IsarDatabase', () {
    test('database can be initialized', () {
      final db = IsarDatabase();
      expect(db, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd packages/lifelab_core
flutter test test/db/isar_database_test.dart
```

Expected: FAIL with "IsarDatabase not defined"

- [ ] **Step 3: Implement User collection**

Create `packages/lifelab_core/lib/db/collections/user_collection.dart`:
```dart
import 'package:isar/isar.dart';

part 'user_collection.g.dart';

@collection
class UserCollection {
  Id id = Isar.autoIncrement;
  String? remoteId;
  String? email;
  String? name;
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

- [ ] **Step 4: Implement SyncMeta collection**

Create `packages/lifelab_core/lib/db/collections/sync_meta_collection.dart`:
```dart
import 'package:isar/isar.dart';

part 'sync_meta_collection.g.dart';

enum SyncStatus { pending, synced, conflict }

@collection
class SyncMetaCollection {
  Id id = Isar.autoIncrement;
  String entityType = '';
  String entityId = '';
  SyncStatus status = SyncStatus.pending;
  DateTime? syncedAt;
  DateTime createdAt = DateTime.now();
}
```

- [ ] **Step 5: Implement IsarDatabase**

Create `packages/lifelab_core/lib/db/isar_database.dart`:
```dart
import 'package:isar/isar.dart';
import 'collections/user_collection.dart';
import 'collections/sync_meta_collection.dart';

class IsarDatabase {
  Isar? _isar;

  Future<void> init() async {
    if (_isar != null) return;
    
    _isar = await Isar.open([
      UserCollectionSchema,
      SyncMetaCollectionSchema,
    ]);
  }

  Isar get instance {
    if (_isar == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
```

- [ ] **Step 6: Run build_runner to generate Isar code**

Run:
```bash
cd packages/lifelab_core
dart run build_runner build
```

Expected: Generated `.g.dart` files for collections

- [ ] **Step 7: Run test to verify it passes**

Run:
```bash
flutter test test/db/isar_database_test.dart
```

Expected: PASS

- [ ] **Step 8: Commit database setup**

Run:
```bash
git add packages/lifelab_core/lib/db/
git add packages/lifelab_core/test/db/
git commit -m "feat: set up Isar database with user and sync_meta collections"
```

Expected: Database committed

---

## Task 4: Implement Dio API Client

**Files:**
- Create: `packages/lifelab_core/lib/api/dio_client.dart`
- Create: `packages/lifelab_core/lib/api/endpoints.dart`
- Create: `packages/lifelab_core/lib/api/api_client.dart`
- Test: `packages/lifelab_core/test/api/api_client_test.dart`

- [ ] **Step 1: Write failing test for API client**

Create `packages/lifelab_core/test/api/api_client_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_core/api/api_client.dart';

void main() {
  group('ApiClient', () {
    test('API client can be instantiated', () {
      final client = ApiClient();
      expect(client, isNotNull);
    });

    test('base URL is set correctly', () {
      final client = ApiClient();
      expect(client.dio.options.baseUrl, equals('https://lifeos-api.lablogicapp.workers.dev'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd packages/lifelab_core
flutter test test/api/api_client_test.dart
```

Expected: FAIL with "ApiClient not defined"

- [ ] **Step 3: Implement Endpoints**

Create `packages/lifelab_core/lib/api/endpoints.dart`:
```dart
class Endpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String profile = '/api/auth/profile';
  static const String changePassword = '/api/auth/change-password';

  // 2FA
  static const String twoFaStatus = '/api/2fa/status';
  static const String twoFaEnable = '/api/2fa/enable';
  static const String twoFaVerify = '/api/2fa/verify';
  static const String twoFaDisable = '/api/2fa/disable';

  // Sessions
  static const String sessions = '/api/sessions';

  // Notes
  static const String notes = '/api/notes';
  static const String folders = '/api/folders';
  static const String tags = '/api/tags';

  // Todos
  static const String todos = '/api/todos';

  // Projects
  static const String projects = '/api/projects';
  static const String boards = '/api/boards';

  // Calendar
  static const String calendar = '/api/calendar';

  // Passwords
  static const String passwords = '/api/passwords';

  // Bookmarks
  static const String bookmarks = '/api/bookmarks';

  // Contacts
  static const String contacts = '/api/contacts';

  // Messages
  static const String messages = '/api/messages';

  // TOTP
  static const String totp = '/api/totp';

  // Drive
  static const String drive = '/api/drive';
  static const String storages = '/api/storages';

  // Photos
  static const String photos = '/api/photos';
  static const String faces = '/api/faces';

  // Videos
  static const String videos = '/api/videos';

  // Dashboard
  static const String dashboard = '/api/dashboard';
  static const String activity = '/api/activity';

  // Search
  static const String search = '/api/search';

  // Export
  static const String exportBackup = '/api/export/backup';
  static const String exportImport = '/api/export/import';

  // Push
  static const String push = '/api/push';
  static const String pushSubscribe = '/api/push/subscribe';
}
```

- [ ] **Step 4: Implement DioClient**

Create `packages/lifelab_core/lib/api/dio_client.dart`:
```dart
import 'package:dio/dio.dart';

class DioClient {
  static const String baseUrl = 'https://lifeos-api.lablogicapp.workers.dev';
  
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }
}
```

- [ ] **Step 5: Implement ApiClient**

Create `packages/lifelab_core/lib/api/api_client.dart`:
```dart
import 'dio_client.dart';

class ApiClient {
  late final DioClient dioClient;

  ApiClient() {
    dioClient = DioClient();
  }

  DioClient get dio => dioClient;
}
```

- [ ] **Step 6: Run test to verify it passes**

Run:
```bash
flutter test test/api/api_client_test.dart
```

Expected: PASS

- [ ] **Step 7: Commit API client**

Run:
```bash
git add packages/lifelab_core/lib/api/
git add packages/lifelab_core/test/api/
git commit -m "feat: implement Dio API client with endpoints"
```

Expected: API client committed

---

## Task 5: Implement Auth Interceptors

**Files:**
- Create: `packages/lifelab_core/lib/api/interceptors/auth_interceptor.dart`
- Create: `packages/lifelab_core/lib/api/interceptors/refresh_interceptor.dart`
- Test: `packages/lifelab_core/test/api/interceptors/auth_interceptor_test.dart`

- [ ] **Step 1: Write failing test for auth interceptor**

Create `packages/lifelab_core/test/api/interceptors/auth_interceptor_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_core/api/interceptors/auth_interceptor.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  group('AuthInterceptor', () {
    late AuthInterceptor interceptor;
    late MockTokenStorage mockTokenStorage;

    setUp(() {
      mockTokenStorage = MockTokenStorage();
      interceptor = AuthInterceptor(mockTokenStorage);
    });

    test('attaches session cookie when token exists', () async {
      // Arrange
      when(() => mockTokenStorage.getSession()).thenAnswer((_) async => 'test-token');
      
      final options = RequestOptions(path: '/api/test');
      final handler = RequestInterceptorHandler();

      // Act
      interceptor.onRequest(options, handler);

      // Assert
      await Future.delayed(Duration.zero);
      expect(options.headers['Cookie'], contains('session=test-token'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd packages/lifelab_core
flutter test test/api/interceptors/auth_interceptor_test.dart
```

Expected: FAIL with "AuthInterceptor not defined"

- [ ] **Step 3: Implement TokenStorage interface**

Create `packages/lifelab_core/lib/auth/token_storage.dart`:
```dart
abstract class TokenStorage {
  Future<void> saveSession(String sessionToken);
  Future<String?> getSession();
  Future<void> clearSession();
}
```

- [ ] **Step 4: Implement AuthInterceptor**

Create `packages/lifelab_core/lib/api/interceptors/auth_interceptor.dart`:
```dart
import 'package:dio/dio.dart';
import '../../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  AuthInterceptor(this.tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.getSession();
    if (token != null) {
      options.headers['Cookie'] = 'session=$token';
    }
    handler.next(options);
  }
}
```

- [ ] **Step 5: Implement RefreshInterceptor**

Create `packages/lifelab_core/lib/api/interceptors/refresh_interceptor.dart`:
```dart
import 'package:dio/dio.dart';

class RefreshInterceptor extends Interceptor {
  final Future<bool> Function() onUnauthorized;

  RefreshInterceptor(this.onUnauthorized);

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final success = await onUnauthorized();
      if (success) {
        handler.resolve(await Dio().fetch(err.requestOptions));
      } else {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run:
```bash
flutter test test/api/interceptors/auth_interceptor_test.dart
```

Expected: PASS

- [ ] **Step 7: Commit interceptors**

Run:
```bash
git add packages/lifelab_core/lib/api/interceptors/
git add packages/lifelab_core/test/api/interceptors/
git commit -m "feat: add auth and refresh interceptors"
```

Expected: Interceptors committed

---

## Task 6: Implement Token Storage

**Files:**
- Create: `packages/lifelab_core/lib/auth/secure_token_storage.dart`
- Test: `packages/lifelab_core/test/auth/secure_token_storage_test.dart`

- [ ] **Step 1: Write failing test for token storage**

Create `packages/lifelab_core/test/auth/secure_token_storage_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_core/auth/secure_token_storage.dart';

void main() {
  group('SecureTokenStorage', () {
    test('can be instantiated', () {
      final storage = SecureTokenStorage();
      expect(storage, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd packages/lifelab_core
flutter test test/auth/secure_token_storage_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement SecureTokenStorage**

Create `packages/lifelab_core/lib/auth/secure_token_storage.dart`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;
  static const _sessionKey = 'session_token';

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveSession(String sessionToken) async {
    await _storage.write(key: _sessionKey, value: sessionToken);
  }

  @override
  Future<String?> getSession() async {
    return await _storage.read(key: _sessionKey);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/auth/secure_token_storage_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit token storage**

Run:
```bash
git add packages/lifelab_core/lib/auth/
git add packages/lifelab_core/test/auth/
git commit -m "feat: implement secure token storage with flutter_secure_storage"
```

Expected: Token storage committed

---

## Task 7: Implement Auth Repository

**Files:**
- Create: `packages/lifelab_core/lib/auth/auth_repository.dart`
- Test: `packages/lifelab_core/test/auth/auth_repository_test.dart`

- [ ] **Step 1: Write failing test for auth repository**

Create `packages/lifelab_core/test/auth/auth_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_core/auth/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  group('AuthRepository', () {
    test('can be instantiated', () {
      final repo = AuthRepository(
        apiClient: MockApiClient(),
        tokenStorage: MockTokenStorage(),
      );
      expect(repo, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd packages/lifelab_core
flutter test test/auth/auth_repository_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement AuthRepository**

Create `packages/lifelab_core/lib/auth/auth_repository.dart`:
```dart
import '../api/api_client.dart';
import '../api/endpoints.dart';
import 'token_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.dio.dio.post(
      Endpoints.login,
      data: {'email': email, 'password': password},
    );
    
    final data = response.data;
    if (data['sessionToken'] != null) {
      await tokenStorage.saveSession(data['sessionToken']);
    }
    
    return data;
  }

  Future<void> verify2FA(String code) async {
    await apiClient.dio.dio.post(
      Endpoints.twoFaVerify,
      data: {'code': code},
    );
  }

  Future<void> logout() async {
    await apiClient.dio.dio.post(Endpoints.logout);
    await tokenStorage.clearSession();
  }

  Future<String?> getSession() => tokenStorage.getSession();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/auth/auth_repository_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit auth repository**

Run:
```bash
git add packages/lifelab_core/lib/auth/auth_repository.dart
git add packages/lifelab_core/test/auth/auth_repository_test.dart
git commit -m "feat: implement auth repository with login, 2FA, logout"
```

Expected: Auth repository committed

---

## Task 8: Create Auth State & Provider

**Files:**
- Create: `packages/lifelab_core/lib/auth/auth_state.dart`
- Create: `packages/lifelab_core/lib/auth/auth_provider.dart`
- Test: `packages/lifelab_core/test/auth/auth_provider_test.dart`

- [ ] **Step 1: Write failing test for auth state**

Create `packages/lifelab_core/test/auth/auth_provider_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_core/auth/auth_state.dart';

void main() {
  group('AuthState', () {
    test('initial state is unauthenticated', () {
      final state = AuthState.initial();
      expect(state.status, equals(AuthStatus.unauthenticated));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd packages/lifelab_core
flutter test test/auth/auth_provider_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement AuthState**

Create `packages/lifelab_core/lib/auth/auth_state.dart`:
```dart
enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  needs2FA,
  authenticated,
  expired,
}

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? name;
  final String? error;

  AuthState({
    required this.status,
    this.userId,
    this.email,
    this.name,
    this.error,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.unauthenticated);
  
  factory AuthState.authenticating() => AuthState(status: AuthStatus.authenticating);
  
  factory AuthState.needs2FA() => AuthState(status: AuthStatus.needs2FA);
  
  factory AuthState.authenticated({
    required String userId,
    String? email,
    String? name,
  }) => AuthState(
    status: AuthStatus.authenticated,
    userId: userId,
    email: email,
    name: name,
  );
  
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  
  factory AuthState.expired() => AuthState(status: AuthStatus.expired);

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? name,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      error: error ?? this.error,
    );
  }
}
```

- [ ] **Step 4: Implement AuthProvider**

Create `packages/lifelab_core/lib/auth/auth_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> checkAuthStatus() async {
    final session = await _repository.getSession();
    if (session != null) {
      state = AuthState.authenticated(userId: 'unknown');
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.authenticating();
    try {
      final result = await _repository.login(email, password);
      
      if (result['needs2FA'] == true) {
        state = AuthState.needs2FA();
      } else {
        state = AuthState.authenticated(
          userId: result['userId'] ?? 'unknown',
          email: email,
        );
      }
    } catch (e) {
      state = AuthState.unauthenticated().copyWith(error: e.toString());
    }
  }

  Future<void> verify2FA(String code) async {
    try {
      await _repository.verify2FA(code);
      state = AuthState.authenticated(userId: 'unknown');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
flutter test test/auth/auth_provider_test.dart
```

Expected: PASS

- [ ] **Step 6: Commit auth state & provider**

Run:
```bash
git add packages/lifelab_core/lib/auth/auth_state.dart
git add packages/lifelab_core/lib/auth/auth_provider.dart
git add packages/lifelab_core/test/auth/auth_provider_test.dart
git commit -m "feat: add auth state management with Riverpod"
```

Expected: Auth state committed

---

## Task 9: Build Login Screen

**Files:**
- Create: `lib/features/auth/presentation/login_screen.dart`
- Create: `lib/features/auth/di/auth_providers.dart`
- Test: `test/features/auth/presentation/login_screen_test.dart`

- [ ] **Step 1: Write failing test for login screen**

Create `test/features/auth/presentation/login_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('login screen displays email and password fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/features/auth/presentation/login_screen_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement LoginScreen**

Create `lib/features/auth/presentation/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/auth/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'LifeLab',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.status == AuthStatus.authenticating
                      ? null
                      : _handleLogin,
                  child: authState.status == AuthStatus.authenticating
                      ? const CircularProgressIndicator()
                      : const Text('Sign In'),
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authState.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create auth providers**

Create `lib/features/auth/di/auth_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/auth/auth_provider.dart';
import 'package:lifelab_core/auth/auth_repository.dart';
import 'package:lifelab_core/auth/secure_token_storage.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/di/core_providers.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final repository = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  return AuthNotifier(repository);
});
```

- [ ] **Step 5: Create core providers**

Create `packages/lifelab_core/lib/di/core_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../auth/token_storage.dart';
import '../auth/secure_token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});
```

- [ ] **Step 6: Run test to verify it passes**

Run:
```bash
flutter test test/features/auth/presentation/login_screen_test.dart
```

Expected: PASS

- [ ] **Step 7: Commit login screen**

Run:
```bash
git add lib/features/auth/
git add test/features/auth/
git add packages/lifelab_core/lib/di/
git commit -m "feat: build login screen with email/password form"
```

Expected: Login screen committed

---

## Task 10: Build 2FA Screen

**Files:**
- Create: `lib/features/auth/presentation/two_factor_screen.dart`
- Test: `test/features/auth/presentation/two_factor_screen_test.dart`

- [ ] **Step 1: Write failing test for 2FA screen**

Create `test/features/auth/presentation/two_factor_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab/features/auth/presentation/two_factor_screen.dart';

void main() {
  testWidgets('2FA screen displays code input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: TwoFactorScreen()),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Enter 6-digit code'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/features/auth/presentation/two_factor_screen_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement TwoFactorScreen**

Create `lib/features/auth/presentation/two_factor_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/auth/auth_provider.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    await ref.read(authProvider.notifier).verify2FA(code);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Enter the 6-digit code from your authenticator app',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Enter 6-digit code',
                  hintText: '000000',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleVerify,
                child: const Text('Verify'),
              ),
              if (authState.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  authState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/features/auth/presentation/two_factor_screen_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit 2FA screen**

Run:
```bash
git add lib/features/auth/presentation/two_factor_screen.dart
git add test/features/auth/presentation/two_factor_screen_test.dart
git commit -m "feat: build 2FA verification screen"
```

Expected: 2FA screen committed

---

## Task 11: Set Up GoRouter with Auth Guard

**Files:**
- Create: `lib/app/router.dart`
- Test: `test/app/router_test.dart`

- [ ] **Step 1: Write failing test for router**

Create `test/app/router_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab/app/router.dart';

void main() {
  test('router can be created', () {
    final router = createRouter(ProviderContainer());
    expect(router, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/app/router_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement Router**

Create `lib/app/router.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelab_core/auth/auth_provider.dart';
import 'package:lifelab_core/auth/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/two_factor_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import 'shell.dart';

GoRouter createRouter(ProviderContainer container) {
  final auth = container.read(authProvider);

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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/2fa',
        builder: (context, state) => const TwoFactorScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref.container);
});
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/app/router_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit router**

Run:
```bash
git add lib/app/router.dart
git add test/app/router_test.dart
git commit -m "feat: set up GoRouter with auth guard and redirect logic"
```

Expected: Router committed

---

## Task 12: Build Navigation Shell

**Files:**
- Create: `lib/app/shell.dart`
- Test: `test/app/shell_test.dart`

- [ ] **Step 1: Write failing test for shell**

Create `test/app/shell_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab/app/shell.dart';

void main() {
  testWidgets('shell displays bottom navigation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(child: const Scaffold(body: Text('Test'))),
      ),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/app/shell_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement AppShell**

Create `lib/app/shell.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Todos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/notes')) return 1;
    if (location.startsWith('/todos')) return 2;
    return 3;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/notes');
        break;
      case 2:
        context.go('/todos');
        break;
      case 3:
        context.go('/more');
        break;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/app/shell_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit shell**

Run:
```bash
git add lib/app/shell.dart
git add test/app/shell_test.dart
git commit -m "feat: build navigation shell with bottom navigation bar"
```

Expected: Shell committed

---

## Task 13: Build Dashboard Screen

**Files:**
- Create: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Test: `test/features/dashboard/presentation/dashboard_screen_test.dart`

- [ ] **Step 1: Write failing test for dashboard**

Create `test/features/dashboard/presentation/dashboard_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('dashboard displays welcome message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/features/dashboard/presentation/dashboard_screen_test.dart
```

Expected: FAIL

- [ ] **Step 3: Implement DashboardScreen**

Create `lib/features/dashboard/presentation/dashboard_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/auth/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome${authState.name != null ? ', ${authState.name}' : ''}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(
                  title: 'Notes',
                  value: '0',
                  icon: Icons.note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Todos',
                  value: '0',
                  icon: Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard(
                  title: 'Projects',
                  value: '0',
                  icon: Icons.work,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  title: 'Calendar',
                  value: '0',
                  icon: Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/features/dashboard/presentation/dashboard_screen_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit dashboard**

Run:
```bash
git add lib/features/dashboard/
git add test/features/dashboard/
git commit -m "feat: build dashboard screen with stat cards"
```

Expected: Dashboard committed

---

## Task 14: Wire Up main.dart and Final Integration

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update main.dart**

Replace `lib/main.dart` with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_ui/theme/app_theme.dart';
import 'app/router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LifeLabApp(),
    ),
  );
}

class LifeLabApp extends ConsumerWidget {
  const LifeLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LifeLab',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Run all tests**

Run:
```bash
flutter test
```

Expected: All tests pass

- [ ] **Step 3: Run the app**

Run:
```bash
flutter run
```

Expected: App launches, shows login screen, can navigate to 2FA, then dashboard

- [ ] **Step 4: Final commit**

Run:
```bash
git add lib/main.dart
git commit -m "feat: wire up main.dart with theme and router"
git tag v0.1.0-phase1-complete
```

Expected: Phase 1 complete

---

## Phase 1 Complete ✓

At this point you have:
- ✅ Flutter project scaffolded with core packages
- ✅ Material 3 theme with light/dark modes
- ✅ Isar database with user and sync_meta collections
- ✅ Dio API client with endpoints and interceptors
- ✅ Secure token storage
- ✅ Auth repository with login, 2FA, logout
- ✅ Auth state management with Riverpod
- ✅ Login screen with email/password form
- ✅ 2FA verification screen
- ✅ GoRouter with auth guard
- ✅ Navigation shell with bottom navigation
- ✅ Dashboard screen with stat cards
- ✅ All tests passing

**Next:** Phase 2 — Core Productivity (Notes, Todos, Projects, Calendar)
