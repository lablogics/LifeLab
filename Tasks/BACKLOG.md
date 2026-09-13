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
  - [ ] ~~Note templates~~ → deferred to Task 62
  - [ ] ~~Wikilinks~~ → deferred to Task 62
  - [ ] ~~Note graph visualization~~ → deferred to Task 62
  - [x] Offline sync with Isar
- [x] **Task 17** Todos feature
  - [x] Todos list with filters (all, active, completed)
  - [x] Create/edit/delete todos
  - [x] Toggle completion
  - [ ] ~~Due dates & reminders~~ → deferred to Task 62
  - [x] Offline sync
- [x] **Task 18** Projects feature
  - [x] Projects list screen
  - [x] Project detail with boards
  - [x] Kanban columns & cards
  - [ ] ~~Drag-and-drop card movement~~ → deferred to Task 62
  - [x] Offline sync
- [x] **Task 19** Calendar feature
  - [x] Month view with events
  - [ ] ~~Create/edit/delete events~~ → deferred to Task 62
  - [x] Date filtering
- [x] **Task 20** Dashboard with real API stats
  - [x] Fetch stats from /api/dashboard/stats
  - [ ] ~~Fetch activity from /api/activity~~ → deferred to Task 62
  - [x] Display real counts in stat cards
- [x] **Task 21** Global search
  - [x] Search screen with categories
  - [x] Search across notes, todos, projects
  - [ ] ~~Recent searches~~ → deferred to Task 62
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
  - [ ] ~~Password generator~~ → deferred to Task 62
- [x] **Task 24** Bookmarks
  - [x] Bookmarks list
  - [x] Add/delete bookmarks
  - [ ] ~~Categories/tags~~ → deferred to Task 62
- [x] **Task 25** Contacts
  - [x] Contacts list
  - [x] Create/delete contacts
- [x] **Task 26** Messages
  - [x] Conversation view
  - [x] Send/receive messages
- [x] **Task 27** TOTP authenticator
  - [x] Display TOTP codes
  - [x] Auto-refresh codes
  - [ ] ~~Add accounts (QR scan / manual)~~ → deferred to Task 62
- [◐] **Task 28** Photos gallery
  - [x] Grid view (basic stub)
  - [ ] Photo viewer
  - [ ] Face detection & clustering
  - [ ] Upload/download
  - [ ] Albums, faces, editing → see `62-lifelab-client-gaps.md`
- [ ] **Task 29** Videos player → see `62-lifelab-client-gaps.md`
- [◐] **Task 30** Drive file browser
  - [x] File/folder list (basic stub)
  - [ ] Upload/download files
  - [ ] Full CRUD → see `62-lifelab-client-gaps.md`
- [ ] **Task 31** Push notifications (FCM) → see `62-lifelab-client-gaps.md`
- [◐] **Task 32** Settings
  - [x] Basic settings screen (stub)
  - [ ] Profile edit, change password, sessions, 2FA, theme → see `62-lifelab-client-gaps.md`

## Phase 4: Client-Only Features ✅
- [x] **Task 33** Mail (local-only) — basic stub
- [x] **Task 34** Voice notes (local-only) — basic stub
- [x] **Task 35** Finance tracker (local-only) — basic stub
- [x] **Task 36** Backup/restore — export/import via /api/export/*

## Phase 5: Polish & Launch
- [ ] **Task 37** Unit tests (70% coverage target)
- [ ] **Task 38** Widget tests
- [ ] **Task 39** Integration tests
- [ ] **Task 40** Performance profiling
- [x] **Task 41** App icons & splash screen — Android adaptive icon generated
- [ ] **Task 42** Release build (APK)

## Remaining Gaps → `LifeOS/Tasks/62-lifelab-client-gaps.md`
New features, stub expansions, UX improvements, and quality work tracked there.
