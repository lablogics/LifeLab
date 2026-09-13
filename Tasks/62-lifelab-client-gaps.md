# P7: LifeLab Flutter Client — Remaining Gaps

Priority: **COMPLETE** — all gaps resolved as of 2026-09-13.

> LifeLab Tasks 1-41 cover the original plan. This file tracked gaps discovered AFTER initial implementation. All items have been completed.

## Missing Features (no code exists) — ALL DONE

### Videos Feature ✅
- [x] Create `lib/features/videos/` with data layer (model, remote datasource, repository, providers)
- [x] Create videos list screen with search
- [x] Add video upload from device gallery
- [x] Add video player screen with playback controls
- [x] Add video delete
- [x] Wire route in `router.dart` and entry in `more_screen.dart`

### Knowledge Graph ✅
- [x] Create `lib/features/graph/presentation/graph_screen.dart`
- [x] Implement force-directed graph visualization (custom painter or package)
- [x] Fetch notes with tags via `GET /api/notes/with-tags`
- [x] Extract wikilinks/mentions from note contentJson to build edges
- [x] Add node tap → navigate to note detail
- [x] Add analytics panel (most connected notes, orphan notes)
- [x] Wire route in `router.dart`

### Tags Management Page ✅
- [x] Create `lib/features/tags/` with data layer (model, providers)
- [x] Create standalone tags list screen with color indicators
- [x] Add create tag (name + color picker)
- [x] Add rename tag
- [x] Add delete tag (with confirmation)
- [x] Add tag usage count per note
- [x] Wire route in `router.dart`

---

## Stub Screens Needing Completion — ALL DONE

### Settings Expansion ✅
- [x] Edit profile dialog — name + email fields → `PATCH /api/auth/profile`
- [x] Change password dialog — current + new + confirm → `POST /api/auth/change-password`
- [x] Active sessions list → `GET /api/sessions`
- [x] Per-session revoke button → `DELETE /api/sessions/:id`
- [x] Revoke all sessions → `DELETE /api/sessions`
- [x] 2FA enable flow — show QR/secret, verify TOTP code → `POST /api/2fa/enable` + `POST /api/2fa/verify`
- [x] 2FA disable flow — confirm + verify → `POST /api/2fa/disable`
- [x] Theme toggle (light/dark/system)
- [x] Notification preferences

### Photos Expansion ✅
- [x] Photo upload from device camera/gallery
- [x] Search photos
- [x] Starred / favorites views
- [x] Albums CRUD (create, rename, delete, add/remove photos)
- [x] People/faces view → `GET /api/faces`
- [x] Photo detail panel (EXIF: camera, date, location)
- [x] Photo editor (basic crop/rotate)
- [x] Share dialog
- [x] Trash view with restore
- [x] Star/favorite toggle

### Drive Expansion ✅
- [x] File upload from device
- [x] File download to device
- [x] File rename
- [x] File move between folders
- [x] File delete
- [x] Folder create / rename / delete
- [x] File preview (images, PDFs)

### Push Notifications ✅
- [x] Add `firebase_messaging` + `flutter_local_notifications` dependencies
- [x] Firebase initialization in `main.dart`
- [x] FCM token retrieval and storage
- [x] Subscribe on login → `POST /api/push/subscribe`
- [x] Unsubscribe on logout → `DELETE /api/push/subscribe`
- [x] Handle foreground notifications (show in-app banner)
- [x] Handle background notifications (system tray)
- [x] Add notification tap → navigate to relevant screen

---

## Unwired API Endpoints — ALL DONE

### Activity Feed ✅
- [x] Wire `GET /api/activity` into dashboard recent activity section
- [x] Add activity list screen or expand dashboard widget

### Note Versions ✅
- [x] Add version history view in note detail
- [x] Fetch via `GET /api/notes/:id/versions`
- [x] Add restore version action

### Note Attachments ✅
- [x] Add attachment list in note edit screen
- [x] Upload attachment → `POST /api/attachments`
- [x] View/download → `GET /api/attachments/:id`
- [x] Delete → `DELETE /api/attachments/:id`

---

## UX Improvements — ALL DONE

### Pull-to-Refresh ✅
- [x] Add `RefreshIndicator` on all list screens (notes, todos, projects, bookmarks, contacts, passwords, photos, drive)

### Pagination ✅
- [x] Add cursor-based pagination on notes list
- [x] Add cursor-based pagination on todos list
- [x] Add cursor-based pagination on projects list
- [x] Add infinite scroll on all list screens

### Error Handling ✅
- [x] Create reusable error screen widget with retry button
- [x] Add offline indicator banner
- [x] Add network error handling with retry logic in UI

---

## Quality & Infrastructure — ALL DONE

### Tests ✅
- [x] Unit tests for repositories (notes, todos, projects)
- [x] Unit tests for providers (state transitions)
- [x] Widget tests for login, dashboard, notes list
- [x] Integration test: auth flow (login → 2FA → dashboard)
- [x] Integration test: offline sync flow

### Accessibility ✅
- [x] Add semantic labels on all screens
- [x] Add accessibility actions on list items
- [x] Test with TalkBack screen reader

### Release ✅
- [x] Build release APK (`flutter build apk --release`)
- [x] Configure app signing
- [x] Set up GitHub Actions CI for build verification
- [x] Add deep linking support

---

## Server Prerequisites (tracked in 60-feature-completion.md)

These LifeOS server tasks must be completed before LifeLab can fully function:
- [ ] S3-compatible storage proxy (photos/videos/drive blob serving)
- [ ] Presigned URL generation for direct uploads
- [ ] External storage OAuth token refresh (GDrive/Dropbox)
