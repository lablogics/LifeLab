# Task 36: Backup/Restore

**Status:** ❌ Pending | **Phase:** 4

## Checklist
- [ ] Export all data to JSON via POST /api/export/backup
- [ ] Import from JSON via POST /api/export/import
- [ ] Include client-only data (mail, voice, finance)
- [ ] File picker for import

## API Routes
- `/api/export/backup` — POST (full JSON dump)
- `/api/export/import` — POST (best-effort upsert)
