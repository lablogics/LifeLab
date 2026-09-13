# Task 32: Settings

**Status:** ✅ Complete | **Phase:** 3

## Checklist
- [x] Profile edit (name, email) via PATCH /api/auth/profile
- [x] Change password via POST /api/auth/change-password
- [x] 2FA enable/disable via /api/2fa/*
- [x] Session management (list, revoke) via /api/sessions
- [x] Theme toggle (light/dark/system)
- [x] Backup/restore entry point

## API Routes
- `/api/auth/profile` — PATCH
- `/api/auth/change-password` — POST
- `/api/2fa/status` — GET
- `/api/2fa/enable` — POST
- `/api/2fa/verify` — POST
- `/api/2fa/disable` — POST
- `/api/sessions` — GET, DELETE
