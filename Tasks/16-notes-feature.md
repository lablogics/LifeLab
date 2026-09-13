# Task 16: Notes Feature

**Status:** ✅ Complete
**Phase:** 2 — Core Productivity

## Checklist

- [x] Notes list screen with search
- [x] Note detail/edit screen with rich text editor (flutter_quill)
- [x] Folders (create, rename, delete, move notes)
- [x] Tags (create, assign, filter)
- [x] Note templates (daily, meeting, project, idea, blank)
- [x] Wikilinks [[note]] support
- [x] Note graph visualization (canvas-based force-directed)
- [x] Daily notes auto-creation
- [x] Offline sync with Isar
- [x] Note version history (via /api/versions)
- [x] Attachments (via /api/attachments)

## API Routes
- `/api/notes` — CRUD
- `/api/folders` — CRUD
- `/api/tags` — CRUD
- `/api/attachments` — File attachments
- `/api/versions` — Note history
- `/api/search` — Full-text search
