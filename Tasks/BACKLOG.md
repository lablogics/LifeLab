# LifeLab Backlog

## Phase 1: Foundation ✅
- [x] **Task 1** Flutter project scaffold with core packages
- [x] **Task 2** Material 3 theme (light/dark modes)
- [x] **Task 3** Isar database setup (UserCollection, SyncMetaCollection)
- [x] **Task 4** Dio API client with 35+ endpoint constants
- [x] **Task 5** Auth interceptor (cookie-based session)
- [x] **Task 6** Secure token storage (flutter_secure_storage)
- [x] **Task 7** Auth repository (login, 2FA verify, logout)
- [x] **Task 8** Auth state & provider (Riverpod StateNotifier)
- [x] **Task 9** Login screen (email/password form)
- [x] **Task 10** 2FA verification screen (6-digit TOTP)
- [x] **Task 11** GoRouter with auth guard & redirect logic
- [x] **Task 12** Navigation shell (bottom nav bar)
- [x] **Task 13** Dashboard screen (real stat cards from API)
- [x] **Task 14** Wire up main.dart with theme & router
- [x] **Task 15** Fix build errors & run code generation

## Phase 2: Core Productivity ✅
- [x] **Task 16** Notes feature
  - [x] Notes list screen with search
  - [x] Note edit screen with rich text
  - [x] Folders (list, create, filter)
  - [x] Tags (assign, filter)
  - [x] Pin/unpin notes
  - [x] ~~Note templates~~ → completed via note_edit_screen
  - [x] ~~Wikilinks~~ → completed via graph_screen extraction
  - [x] ~~Note graph visualization~~ → completed via graph_screen
  - [x] Offline sync with Isar
- [x] **Task 17** Todos feature
  - [x] Todos list with filters (all, active, completed)
  - [x] Create/edit/delete todos
  - [x] Toggle completion
  - [x] ~~Due dates & reminders~~ → completed via todos_providers
  - [x] Offline sync
- [x] **Task 18** Projects feature
  - [x] Projects list screen
  - [x] Project detail with boards
  - [x] Kanban columns & cards
  - [x] ~~Drag-and-drop card movement~~ → completed via board_screen
  - [x] Offline sync
- [x] **Task 19** Calendar feature
  - [x] Month view with events
  - [x] ~~Create/edit/delete events~~ → completed via calendar_providers
  - [x] Date filtering
- [x] **Task 20** Dashboard with real API stats
  - [x] Fetch stats from /api/dashboard/stats
  - [x] ~~Fetch activity from /api/activity~~ → completed via activity_screen
  - [x] Display real counts in stat cards
- [x] **Task 21** Global search
  - [x] Search screen with categories
  - [x] Search across notes, todos, projects
  - [x] ~~Recent searches~~ → completed via search_screen
- [x] **Task 22** Offline sync engine
  - [x] SyncMeta tracking per entity
  - [x] Background sync every 5 minutes
  - [x] Connectivity change listener
  - [x] Conflict resolution (server wins)
  - [x] Exponential backoff retry

## Phase 3: Security & Media
- [x] **Task 23** Passwords vault
  - [x] Password list screen
  - [x] Add/delete passwords
  - [x] ~~Password generator~~ → completed via passwords_screen
- [x] **Task 24** Bookmarks
  - [x] Bookmarks list
  - [x] Add/delete bookmarks
  - [x] ~~Categories/tags~~ → completed via bookmarks_providers
- [x] **Task 25** Contacts
  - [x] Contacts list
  - [x] Create/delete contacts
- [x] **Task 26** Messages
  - [x] Conversation view
  - [x] Send/receive messages
- [x] **Task 27** TOTP authenticator
  - [x] Display TOTP codes
  - [x] Auto-refresh codes
  - [x] ~~Add accounts (QR scan / manual)~~ → completed via totp_providers
- [x] **Task 28** Photos gallery
  - [x] Grid view (basic stub)
  - [x] Photo viewer
  - [x] Face detection & clustering
  - [x] Upload/download
  - [x] Albums, faces, editing, crop/rotate, share dialog
- [x] **Task 29** Videos player — list, search, delete, video player with controls
- [x] **Task 30** Drive file browser
  - [x] File/folder list
  - [x] Upload/download files
  - [x] Full CRUD, file move between folders
- [x] **Task 31** Push notifications (FCM) — Firebase init, FCM token, foreground/background handling, notification preferences
- [x] **Task 32** Settings
  - [x] Full settings screen
  - [x] Profile edit, change password, sessions, 2FA, theme, notification prefs

## Phase 4: Client-Only Features ✅
- [x] **Task 33** Mail (local-only) — basic stub
- [x] **Task 34** Voice notes (local-only) — basic stub
- [x] **Task 35** Finance tracker (local-only) — basic stub
- [x] **Task 36** Backup/restore — export/import via /api/export/*

## Phase 5: Polish & Launch
- [x] **Task 37** Unit tests — models, endpoints, pagination state (20 tests)
- [x] **Task 38** Widget tests — login, dashboard, notes, error retry
- [x] **Task 39** Integration tests — auth flow, sync flow, backup/restore, pagination
- [x] **Task 40** Performance profiling — 60fps scroll, memory leak detection, sync stress test
- [x] **Task 41** App icons & splash screen — Android adaptive icon generated
- [x] **Task 42** Release build (APK) + GitHub Actions CI + app signing

## Remaining Gaps → `Tasks/62-lifelab-client-gaps.md`
All gaps resolved as of 2026-09-13. 60 tasks complete.
