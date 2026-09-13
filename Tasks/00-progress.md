# LifeLab Progress Board

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | Flutter project scaffold (pnpm workspace, 3 packages) | ✅ | lifelab_core, lifelab_ui, root app |
| 2 | Material 3 theme (light/dark) | ✅ | AppTheme, AppColors, AppTypography |
| 3 | Isar database setup (2 collections) | ✅ | UserCollection, SyncMetaCollection |
| 4 | Dio API client with endpoints | ✅ | 35+ endpoints mapped |
| 5 | Auth interceptor (cookie-based) | ✅ | Auto-attach session token |
| 6 | Secure token storage | ✅ | flutter_secure_storage wrapper |
| 7 | Auth repository (login, 2FA, logout) | ✅ | Full auth flow |
| 8 | Auth state & provider (Riverpod) | ✅ | StateNotifier with AuthStatus enum |
| 9 | Login screen | ✅ | Email/password form with validation |
| 10 | 2FA verification screen | ✅ | 6-digit TOTP input |
| 11 | GoRouter with auth guard | ✅ | Redirect logic for auth/2FA/dashboard |
| 12 | Navigation shell (bottom nav) | ✅ | Dashboard, Notes, Todos, More |
| 13 | Dashboard screen | ✅ | Stat cards, welcome message, logout |
| 14 | Wire up main.dart | ✅ | ProviderScope + MaterialApp.router |
| 15 | Fix build errors (CardTheme, Isar @enumerated) | ✅ | Code generation passing |
| 16 | Notes feature (list, detail, create, edit, folders, tags) | ❌ | Phase 2 |
| 17 | Todos feature (list, create, toggle, due dates) | ❌ | Phase 2 |
| 18 | Projects feature (list, boards, kanban) | ❌ | Phase 2 |
| 19 | Calendar feature (month view, events) | ❌ | Phase 2 |
| 20 | Dashboard with real stats from API | ❌ | Phase 2 |
| 21 | Global search | ❌ | Phase 2 |
| 22 | Offline sync for core features | ❌ | Phase 2 |
| 23 | Passwords vault | ❌ | Phase 3 |
| 24 | Bookmarks | ❌ | Phase 3 |
| 25 | Contacts | ❌ | Phase 3 |
| 26 | Messages | ❌ | Phase 3 |
| 27 | TOTP authenticator | ❌ | Phase 3 |
| 28 | Photos gallery + face detection | ❌ | Phase 3 |
| 29 | Videos player | ❌ | Phase 3 |
| 30 | Drive file browser | ❌ | Phase 3 |
| 31 | Push notifications (FCM) | ❌ | Phase 3 |
| 32 | Settings (profile, sessions, change password) | ❌ | Phase 3 |
| 33 | Mail (local-only) | ❌ | Phase 4 |
| 34 | Voice notes (local-only) | ❌ | Phase 4 |
| 35 | Finance tracker (local-only) | ❌ | Phase 4 |
| 36 | Backup/restore (export/import) | ❌ | Phase 4 |
| 37 | Unit tests (70% coverage) | ❌ | Phase 5 |
| 38 | Widget tests | ❌ | Phase 5 |
| 39 | Integration tests | ❌ | Phase 5 |
| 40 | Performance profiling | ❌ | Phase 5 |
| 41 | App icons & splash screen | ❌ | Phase 5 |
| 42 | Release build (APK/AAB + IPA) | ❌ | Phase 5 |
