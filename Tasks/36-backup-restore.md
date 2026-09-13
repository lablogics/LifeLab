# Task 36: Backup/Restore

**Status:** ✅ Complete | **Phase:** 4

## Checklist
- [x] Export all data to JSON via POST /api/export/backup
- [x] Import from JSON via POST /api/export/import
- [x] Include client-only data (mail, voice, finance)
- [x] File picker for import

## API Routes
- `/api/export/backup` — POST (full JSON dump)
- `/api/export/import` — POST (best-effort upsert)
