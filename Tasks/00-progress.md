# LifeLab Progress Board

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | Flutter project scaffold (pnpm workspace, 3 packages) | ✅ | lifelab_core, lifelab_ui, root app |
| 2 | Material 3 theme (light/dark) | ✅ | AppTheme, AppColors, AppTypography |
| 3 | Isar database setup (2 collections) | ✅ | UserCollection, SyncMetaCollection |
| 4 | Dio API client with endpoints | ✅ | 45+ endpoints mapped |
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
| 16 | Notes feature (list, edit, folders, tags) | ✅ | List, edit, folders, tags, pin, versions, attachments |
| 17 | Todos feature (list, create, toggle, filters) | ✅ | List, create, toggle, delete, filters |
| 18 | Projects feature (list, boards, kanban) | ✅ | List, boards, kanban columns |
| 19 | Calendar feature (month view) | ✅ | Month view with events |
| 20 | Dashboard with real stats from API | ✅ | Fetches /api/dashboard/stats |
| 21 | Global search | ✅ | Search across notes, todos, projects |
| 22 | Offline sync engine | ✅ | Queue, background sync, wired into notes/todos/projects |
| 23 | Passwords vault | ✅ | List + create/delete |
| 24 | Bookmarks | ✅ | List + create/delete |
| 25 | Contacts | ✅ | List + create/delete |
| 26 | Messages | ✅ | Conversation view |
| 27 | TOTP authenticator | ✅ | Display codes, auto-refresh |
| 28 | Photos gallery | ✅ | Grid, search, starred/favorites, detail panel, star/trash |
| 29 | Videos player | ✅ | List, search, delete, size display |
| 30 | Drive file browser | ✅ | Folder nav, create folder, rename, delete, breadcrumb |
| 31 | Push notifications (FCM) | ❌ | Needs firebase_messaging setup |
| 32 | Settings | ✅ | Profile edit, password, sessions, 2FA toggle, theme, activity/tags/graph/videos nav |
| 33 | Mail (local-only) | ✅ | Basic stub with local storage |
| 34 | Voice notes (local-only) | ✅ | Basic stub with local storage |
| 35 | Finance tracker (local-only) | ✅ | Basic stub with local storage |
| 36 | Backup/restore (export/import) | ✅ | Export/import via /api/export/* |
| 37 | Tags management page | ✅ | CRUD, color picker, note count |
| 38 | Knowledge graph | ✅ | Force-directed graph, analytics panel |
| 39 | Activity feed | ✅ | List from /api/activity |
| 40 | Note versions | ✅ | History list, restore action |
| 41 | Note attachments | ✅ | List, delete |
| 42 | Error handling widgets | ✅ | ErrorScreen, OfflineBanner |
| 43 | App icons & splash screen | ✅ | Android adaptive icon generated |
| 44 | Pull-to-refresh | ✅ | On all list screens |
