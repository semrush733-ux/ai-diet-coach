# AI Diet Coach — Architecture Overview (Phase 1)

## System components

```
┌───────────────┐      ┌───────────────┐
│  Flutter App  │      │  Next.js      │
│ (Android/iOS) │      │  Admin        │
└───────┬───────┘      └───────┬───────┘
        │  HTTPS (REST, JSON)  │
        ▼                      ▼
┌──────────────────────────────────────┐
│          Nginx (TLS termination)     │
└───────────────────┬──────────────────┘
                    ▼
┌──────────────────────────────────────┐
│        Laravel 11 API (v1)           │
│  Sanctum auth · RBAC · Validation    │
│  ┌────────────────────────────────┐  │
│  │  Meal Planning Engine          │  │
│  │  A. Verified food DB           │  │
│  │  B. Deterministic rules        │  │
│  │  C. AI recommendation layer    │  │
│  │  D. Validation / safety gate   │  │
│  └────────────────────────────────┘  │
│  AI Gateway (provider-agnostic,      │
│  server-side keys only)              │
│  Queues · Scheduler · Notifications  │
└───────┬──────────────┬───────────────┘
        ▼              ▼
  PostgreSQL 16      Redis 7
  (normalized        (cache, queues,
   schema)            rate limiting)
```

## Key architectural decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | **Hybrid planning engine (DB + rules + AI + validation)** | LLMs are never trusted alone for clinically consequential numbers. Nutrient math is deterministic; AI only suggests variations that then pass the validation gate (allergy exclusion, restriction checks, arithmetic verification). |
| 2 | **API versioning from day one (`/api/v1`)** | Mobile clients live long in the wild; breaking changes go to v2. |
| 3 | **Sanctum personal access tokens** | Appropriate for first-party mobile apps; refresh handled via token rotation endpoint; secure storage on device via Keychain/Keystore. |
| 4 | **Glucose stored in canonical mg/dL + original value/unit** | Lossless round-tripping between mg/dL and mmol/L (factor 18.016 for glucose, rounded per clinical convention 18.0 documented in `docs/nutrition/units.md`). Original reading is never discarded. |
| 5 | **Health data isolation** | `user_health_profiles`, `glucose_readings`, `hba1c_results` are only readable through user-scoped policies. Admin roles do **not** get these by default; access requires an explicit permission + audit log entry. |
| 6 | **Safety rules as versioned backend data** | `safety_rule_versions` table; clinically reviewed messages are content, not hardcoded strings, so they can be reviewed/updated without an app release. |
| 7 | **Feature flags** | Food photo scanner and other experimental AI features ship behind server-driven flags (`config/features.php` → remote config later). |
| 8 | **Localization-first** | All mobile strings via ARB files (en, ur initially; RTL supported). Food names localized via `food_translations`. |
| 9 | **Offline-tolerant mobile core** | Repository pattern with local cache layer (Phase 2+); writes queued with client-generated UUIDs for idempotent sync, never silent overwrite (server compares `updated_at`/version). |
| 10 | **Dev adapters for external services** | FCM/APNs, Google/Apple sign-in, AI provider, store billing are interfaces with a clearly labeled `Fake*`/`LogOnly*` dev implementation and `PENDING CONFIGURATION` markers. |

## Mobile architecture (Flutter)

- **Layers:** `features/<name>/presentation` (screens/widgets) → `application` (Riverpod controllers) → `domain` (entities) → `data` (repositories, DTOs, Dio API client).
- **State:** Riverpod (`Notifier`/`AsyncNotifier`). No business logic in widgets.
- **Navigation:** GoRouter with a `StatefulShellRoute` for the 4 bottom tabs (Home, My Diet, Sugar, Progress) and route guards driven by auth/onboarding state.
- **Design system:** `lib/app/theme/tokens.dart` (colors, spacing, radii, typography) + `app_theme.dart` (light/dark `ThemeData`). Shared widgets in `lib/shared/widgets`.
- **Networking:** `core/network/api_client.dart` — Dio with auth interceptor, retry/backoff, typed error mapping (`ApiException`).
- **Secure storage:** tokens in `flutter_secure_storage`; non-sensitive prefs in `shared_preferences`.

## Backend architecture (Laravel)

- **Controllers** are thin; validation in FormRequests; domain logic in `app/Services`.
- **Policies** enforce user-scoped access to all health records.
- **Consistent JSON envelope:** `{ "data": ..., "meta": ... }` on success; `{ "error": { "code", "message", "details" } }` on failure.
- **Rate limiting:** per-user and per-IP throttles on auth and AI endpoints.
- **Auditability:** `audit_logs` for admin actions and sensitive-data access.

## Security architecture (summary)

- TLS everywhere; HSTS at Nginx in production.
- Argon2id password hashing (Laravel default bcrypt acceptable; config pinned in `config/hashing.php`).
- Server-side AI keys only; the mobile app never holds provider credentials.
- Least-privilege admin RBAC (6 roles) + audit logging.
- Full detail: `docs/security/security-architecture.md`.

## What Phase 1 deliberately does NOT include

- Working external integrations (push, social sign-in, billing, AI provider) — interfaces + dev adapters only.
- The meal-generation algorithm itself (Phase 3) — contracts and schema are in place.
- Populated verified nutrition data — seeders contain a small, clearly labeled development dataset with sourced example values and `data_quality_status = 'dev_seed'`.
