# Task 32: Settings

**Status:** ❌ Pending | **Phase:** 3

## Checklist
- [ ] Profile edit (name, email) via PATCH /api/auth/profile
- [ ] Change password via POST /api/auth/change-password
- [ ] 2FA enable/disable via /api/2fa/*
- [ ] Session management (list, revoke) via /api/sessions
- [ ] Theme toggle (light/dark/system)
- [ ] Backup/restore entry point

## API Routes
- `/api/auth/profile` — PATCH
- `/api/auth/change-password` — POST
- `/api/2fa/status` — GET
- `/api/2fa/enable` — POST
- `/api/2fa/verify` — POST
- `/api/2fa/disable` — POST
- `/api/sessions` — GET, DELETE
