# API Contract — v1 (Phase 1 subset)

Base URL: `/api/v1`. Auth: `Authorization: Bearer <token>` (Sanctum). All responses JSON.

## Envelope
Success: `{ "data": <object|array>, "meta": { ...pagination } }`
Error: `{ "error": { "code": "string", "message": "human readable", "details": {field: [msgs]} } }`
HTTP codes: 200/201, 204, 400, 401, 403, 404, 422, 429, 500, 501 (not yet implemented feature).

## Auth
| Method | Path | Body | Notes |
|---|---|---|---|
| POST | /auth/register | name, email, password, password_confirmation, locale?, timezone? | 201 → user + token; sends verification email (dev: logged) |
| POST | /auth/login | email, password, device_name | 200 → token |
| POST | /auth/logout | — | revokes current token |
| POST | /auth/forgot-password | email | always 200 (no enumeration) |
| POST | /auth/resend-verification | — | throttled |

Throttle: 10/min per IP on auth routes.

## Profile & onboarding
- `GET /profile` → profile + units + locale.
- `PATCH /profile` → partial update (display_name, height_cm, weight_kg, unit_system, country_code, timezone, locale...). Server stores metric canonical.
- `GET /health-profile` / `PATCH /health-profile` → consent-gated; diabetes_status, glucose_unit, clinician targets (accepted in either unit, stored mg/dL canonical).
- `POST /onboarding/complete` → full wizard payload (profile, goals[], health, preferences[], allergies[], schedule, budget). Validates everything atomically; marks `onboarded_at`; returns 201. Meal generation itself: Phase 3 (`POST /meal-plans/generate` returns 501 with `{"error":{"code":"not_implemented"}}` until then).

## Foods
- `GET /foods?query=&country=&category=&vegetarian=&halal=&exclude_allergens[]=&max_kcal=&max_carbs_g=&page=` → paginated; each item includes `nutrition_per_100` with explicit `null` for missing values and `data_quality_status`.
- `GET /foods/{id}` → detail incl. source provenance.

## Glucose
- `GET /glucose-readings?from=&to=&context=&page=`
- `POST /glucose-readings` `{ value, unit: "mg_dl"|"mmol_l", context, measured_at, minutes_since_meal?, note? }` — server stores original + canonical mg/dL (× 18.016 from mmol/L, rounded to 1 dp mg/dL ↔ 2 dp mmol/L).
- `PATCH /glucose-readings/{id}`, `DELETE /glucose-readings/{id}` — owner-only (policy).

## HbA1c
- `GET /hba1c`, `POST /hba1c` `{ value_percent, tested_at, lab_name?, note? }`.

## Meal plans (contract defined; generator Phase 3)
- `POST /meal-plans/generate` `{ duration: today|tomorrow|3d|7d|14d|30d }` → 501 in Phase 1/2.
- `GET /meal-plans/today`, `GET /meal-plans/week` → plan with days→meals, each meal carrying `nutrition_snapshot` + provenance.
- `PATCH /planned-meals/{id}` (time/serving/status), `POST /planned-meals/{id}/replace`, `POST /planned-meals/{id}/complete`.

## Settings & privacy
- `GET /settings`, `PATCH /settings` (notification prefs, quiet hours).
- `POST /privacy/export` → queues export job, 202.
- `POST /privacy/delete-account` `{ password }` → schedules deletion with grace period, 202.

## Admin (separate guard `auth:sanctum` + admin ability; Phase 2)
- `POST /admin/auth/login`
- `GET /admin/stats/overview` → real counts only (users, onboarded, foods, readings). No fabricated metrics.

Full OpenAPI spec will be generated from FormRequests + resources in Phase 2 (`docs/api/openapi.yaml` placeholder committed).
