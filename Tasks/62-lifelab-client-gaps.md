# P7: LifeLab Flutter Client — Remaining Gaps

Priority: **MEDIUM** — gaps between LifeLab mobile app and LifeOS web parity.

> LifeLab Tasks 1-41 cover the original plan. This file tracks what was discovered missing AFTER initial implementation. Items already tracked in `60-feature-completion.md` (S3 proxy, i18n, bulk ops) are NOT duplicated here — those are server-side prerequisites.

## Missing Features (no code exists)

### Videos Feature
- [ ] Create `lib/features/videos/` with data layer (model, remote datasource, repository, providers)
- [ ] Create videos list screen with search
- [ ] Add video upload from device gallery
- [ ] Add video player screen with playback controls
- [ ] Add video delete
- [ ] Wire route in `router.dart` and entry in `more_screen.dart`
- API: `GET /api/videos`, `POST /api/videos`, `DELETE /api/videos/:id`

### Knowledge Graph
- [ ] Create `lib/features/graph/presentation/graph_screen.dart`
- [ ] Implement force-directed graph visualization (custom painter or package)
- [ ] Fetch notes with tags via `GET /api/notes/with-tags`
- [ ] Extract wikilinks/mentions from note contentJson to build edges
- [ ] Add node tap → navigate to note detail
- [ ] Add analytics panel (most connected notes, orphan notes)
- [ ] Wire route in `router.dart`

### Tags Management Page
- [ ] Create `lib/features/tags/` with data layer (model, providers)
- [ ] Create standalone tags list screen with color indicators
- [ ] Add create tag (name + color picker)
- [ ] Add rename tag
- [ ] Add delete tag (with confirmation)
- [ ] Add tag usage count per note
- [ ] Wire route in `router.dart`
- API: `GET /api/tags`, `POST /api/tags`, `PUT /api/tags/:id`, `DELETE /api/tags/:id`

---

## Stub Screens Needing Completion

### Settings Expansion (currently 35-line stub)
- [ ] Edit profile dialog — name + email fields → `PATCH /api/auth/profile`
- [ ] Change password dialog — current + new + confirm → `POST /api/auth/change-password`
- [ ] Active sessions list → `GET /api/sessions`
- [ ] Per-session revoke button → `DELETE /api/sessions/:id`
- [ ] Revoke all sessions → `DELETE /api/sessions`
- [ ] 2FA enable flow — show QR/secret, verify TOTP code → `POST /api/2fa/enable` + `POST /api/2fa/verify`
- [ ] 2FA disable flow — confirm + verify → `POST /api/2fa/disable`
- [ ] Theme toggle (light/dark/system)
- [ ] Notification preferences

### Photos Expansion (currently 37-line stub)
- [ ] Photo upload from device camera/gallery
- [ ] Search photos
- [ ] Starred / favorites views
- [ ] Albums CRUD (create, rename, delete, add/remove photos)
- [ ] People/faces view → `GET /api/faces`
- [ ] Photo detail panel (EXIF: camera, date, location)
- [ ] Photo editor (basic crop/rotate)
- [ ] Share dialog
- [ ] Trash view with restore
- [ ] Star/favorite toggle
- API: `GET /api/photos`, `POST /api/photos`, `DELETE /api/photos/:id`, `GET /api/photos/starred`, `GET /api/photos/search`, `GET /api/faces`

### Drive Expansion (currently 39-line stub)
- [ ] File upload from device
- [ ] File download to device
- [ ] File rename
- [ ] File move between folders
- [ ] File delete
- [ ] Folder create / rename / delete
- [ ] File preview (images, PDFs)
- API: `GET /api/drive`, `POST /api/drive`, `DELETE /api/drive/:id`

### Push Notifications (no code exists)
- [ ] Add `firebase_messaging` + `flutter_local_notifications` dependencies
- [ ] Firebase initialization in `main.dart`
- [ ] FCM token retrieval and storage
- [ ] Subscribe on login → `POST /api/push/subscribe`
- [ ] Unsubscribe on logout → `DELETE /api/push/subscribe`
- [ ] Handle foreground notifications (show in-app banner)
- [ ] Handle background notifications (system tray)
- [ ] Add notification tap → navigate to relevant screen

---

## Unwired API Endpoints

### Activity Feed
- [ ] Wire `GET /api/activity` into dashboard recent activity section
- [ ] Add activity list screen or expand dashboard widget

### Note Versions
- [ ] Add version history view in note detail
- [ ] Fetch via `GET /api/notes/:id/versions`
- [ ] Add restore version action

### Note Attachments
- [ ] Add attachment list in note edit screen
- [ ] Upload attachment → `POST /api/attachments`
- [ ] View/download → `GET /api/attachments/:id`
- [ ] Delete → `DELETE /api/attachments/:id`

---

## UX Improvements

### Pull-to-Refresh
- [ ] Add `RefreshIndicator` on all list screens (notes, todos, projects, bookmarks, contacts, passwords, photos, drive)

### Pagination
- [ ] Add cursor-based pagination on notes list
- [ ] Add cursor-based pagination on todos list
- [ ] Add cursor-based pagination on projects list
- [ ] Add infinite scroll on all list screens

### Error Handling
- [ ] Create reusable error screen widget with retry button
- [ ] Add offline indicator banner
- [ ] Add network error handling with retry logic in UI

---

## Quality & Infrastructure

### Tests
- [ ] Unit tests for repositories (notes, todos, projects)
- [ ] Unit tests for providers (state transitions)
- [ ] Widget tests for login, dashboard, notes list
- [ ] Integration test: auth flow (login → 2FA → dashboard)
- [ ] Integration test: offline sync flow

### Accessibility
- [ ] Add semantic labels on all screens
- [ ] Add accessibility actions on list items
- [ ] Test with TalkBack screen reader

### Release
- [ ] Build release APK (`flutter build apk --release`)
- [ ] Configure app signing
- [ ] Set up GitHub Actions CI for build verification
- [ ] Add deep linking support

---

## Server Prerequisites (tracked in 60-feature-completion.md)

These LifeOS server tasks must be completed before LifeLab can fully function:
- [ ] S3-compatible storage proxy (photos/videos/drive blob serving)
- [ ] Presigned URL generation for direct uploads
- [ ] External storage OAuth token refresh (GDrive/Dropbox)
