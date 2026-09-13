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
| 13 | Dashboard screen | ✅ | Real stat cards from API, activity feed |
| 14 | Wire up main.dart | ✅ | ProviderScope + MaterialApp.router |
| 15 | Fix build errors (CardTheme, Isar @enumerated) | ✅ | Code generation passing |
| 16 | Notes feature (list, edit, folders, tags) | ✅ | List, edit, folders, tags, pin — missing: graph, templates, wikilinks |
| 17 | Todos feature (list, create, toggle, filters) | ✅ | List, create, toggle, delete, filters — missing: due date reminders |
| 18 | Projects feature (list, boards, kanban) | ✅ | List, boards, kanban columns — missing: drag-and-drop |
| 19 | Calendar feature (month view) | ✅ | Month view with events — missing: event CRUD |
| 20 | Dashboard with real stats from API | ✅ | Fetches /api/dashboard/stats |
| 21 | Global search | ✅ | Search across notes, todos, projects |
| 22 | Offline sync engine | ✅ | Queue, background sync, wired into notes/todos/projects |
| 23 | Passwords vault | ✅ | Basic list + create/delete |
| 24 | Bookmarks | ✅ | Basic list + create/delete |
| 25 | Contacts | ✅ | Basic list + create/delete |
| 26 | Messages | ✅ | Basic conversation view |
| 27 | TOTP authenticator | ✅ | Display codes, auto-refresh |
| 28 | Photos gallery | ◐ | Basic grid stub — needs upload, albums, faces, editing (see Task 62) |
| 29 | Videos player | ❌ | Not started — see Task 62 |
| 30 | Drive file browser | ◐ | Basic list stub — needs upload, download, CRUD (see Task 62) |
| 31 | Push notifications (FCM) | ❌ | Not started — see Task 62 |
| 32 | Settings | ◐ | Stub only — needs profile, password, sessions, 2FA, theme (see Task 62) |
| 33 | Mail (local-only) | ✅ | Basic stub with local storage |
| 34 | Voice notes (local-only) | ✅ | Basic stub with local storage |
| 35 | Finance tracker (local-only) | ✅ | Basic stub with local storage |
| 36 | Backup/restore (export/import) | ✅ | Export/import via /api/export/* |
| 37 | Unit tests (70% coverage) | ❌ | Phase 5 |
| 38 | Widget tests | ❌ | Phase 5 |
| 39 | Integration tests | ❌ | Phase 5 |
| 40 | Performance profiling | ❌ | Phase 5 |
| 41 | App icons & splash screen | ✅ | Android adaptive icon generated |
| 42 | Release build (APK) | ❌ | Only debug APK exists (176MB) |
