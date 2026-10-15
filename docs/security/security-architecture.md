# Security Architecture (Phase 1)

## Authentication & sessions
- Sanctum bearer tokens per device (`device_name`), revocable individually (device session management).
- Passwords hashed (Laravel hashing config; bcrypt cost ≥ 12 or argon2id). Never logged, never returned.
- Email verification required before health-profile writes.
- Password reset via signed, expiring tokens; responses never reveal account existence.
- Mobile: tokens only in flutter_secure_storage (Keychain/Android Keystore). Optional biometric unlock gates local app access, not the token itself (Phase 2).

## Authorization
- Every user-owned resource behind a Policy (`GlucoseReadingPolicy`, etc.) — ownership checked server-side on every request.
- Admin RBAC: super_admin, operations_admin, nutrition_content_manager, dietitian_reviewer, support_agent, analyst_readonly. Permissions are explicit grants; health-record access additionally requires `health.read` and writes an `audit_logs` row.

## Transport & secrets
- TLS only; HSTS + modern ciphers at Nginx (prod config template in infrastructure/nginx).
- Secrets via environment variables; `.env` files git-ignored; no keys in mobile binaries — AI/provider calls proxied through backend.

## Input & abuse protection
- FormRequest validation on every endpoint; strict type casting; pagination caps.
- Rate limiting: `throttle:auth` 10/min, `throttle:api` 60/min/user, `throttle:ai` 20/min/user (tightened later by plan).
- File uploads (avatars, food images): mime + size validation, stored outside webroot / object storage, randomized names.
- AI prompt-injection defenses (Phase 5): system-prompt isolation, tool-call allowlist, output schema validation, user-content delimiting; user data never interpolated into provider system prompts.

## Data protection
- Health tables isolated; minimal collection; consent records (`user_health_consents`) are append-only.
- Data export + account deletion endpoints with grace-period purge job.
- Encryption at rest: rely on disk/managed-DB encryption; field-level encryption to be evaluated for clinician targets/notes in Phase 2.
- Audit logs append-only; no sensitive payloads inside them.

## Operational
- Dependency scanning (composer audit, `flutter pub outdated`, npm audit) wired into CI (Phase 2 pipeline).
- Structured JSON logs; no PHI in logs; error monitoring hooks (Sentry-compatible) pending configuration.
- Backups: pg_dump nightly in prod compose/deployment docs; restore drill checklist in docs/deployment.

## Compliance posture
Implementing security controls does **not** constitute HIPAA/GDPR/medical-device compliance. Market-specific legal review (GDPR/UK GDPR, US health privacy, store policies) and a medical-device software assessment are required before launch. Tracked in docs/nutrition/safety-review-checklist.md.
