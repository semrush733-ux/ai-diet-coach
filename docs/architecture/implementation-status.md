# Implementation Status — honest ledger

Updated: Phase 1 delivery + standalone core features round.

## New in the standalone-features round (mobile, no backend required)
- On-device rules-based meal plan generator (7-day): allergy exclusion (never relaxed), dietary prefs (halal/veg/vegan/dairy-free/gluten-free), country + budget with safe relaxation, carb-conscious ranking for diabetes-support goals, portion scaling toward a non-clinical energy heuristic.
- In-app food/meal-template catalog (PK/UK/US, dev-grade USDA-style per-100 g values — re-verify before production).
- My Diet tab: 7-day selector, day totals, meal list; Meal detail: ingredients with grams, nutrition, serving-size adjust, mark eaten/skip; Replace This Meal with kcal/carb deltas.
- Sugar tab: glucose add/history/delete (mg/dL + mmol/L, original kept, 18.016 conversion), 7-day daily-average trend bars, HbA1c entries.
- Progress tab: meals-completed adherence, 7-day glucose average, water glasses tracker, weight log.
- Local persistence (SharedPreferences JSON) for profile, plan, session, tracking — survives app restarts. Standalone auth sessions persist on-device.
These run in the standalone (USE_FAKE_API) build; server-backed equivalents remain Phase 2/3 work.

## Implemented in this repository (code exists, compiles by design, not yet device/CI-verified)

### Mobile (Flutter)
- Design tokens + light/dark themes (brand palette, typography, spacing, radii).
- Shared widget library: primary/secondary buttons, app card, section header, skeleton loader, empty/error states, labeled text field, selectable chip.
- GoRouter navigation: splash → welcome → auth → onboarding wizard → main shell (Home / My Diet / Sugar / Progress tabs) with auth/onboarding redirect guards.
- Auth screens: Splash, Welcome, Sign Up, Login, Forgot Password, Email Verification (UI + validation + controller wiring to repository).
- Auth repository with Dio-backed `ApiAuthRepository` and a clearly labeled `DevFakeAuthRepository` (in-memory, for running without a backend; selected via `--dart-define=USE_FAKE_API=true`).
- 8-step onboarding wizard (basic profile, goals, health info, food preferences, schedule, budget, review/generate) with Riverpod draft state and unit conversion (kg/lb, cm/ft-in).
- Home dashboard screen consuming typed models; renders real plan data when backend provides it, and an explicit "no plan yet" empty state otherwise (no fake statistics).
- Localization foundation: ARB files for English + Urdu, RTL-ready.

### Backend (Laravel skeleton)
- `composer.json`, config stubs, `.env.example`.
- `routes/api.php` — full v1 route map (auth, profile, onboarding, meal plans, foods, glucose, hba1c, progress, settings/privacy) with `auth:sanctum` + throttling groups.
- Controllers implemented: AuthController (register, login, logout, forgot-password), ProfileController, OnboardingController, GlucoseReadingController (with mg/dL↔mmol/L canonical conversion), FoodController (search/filter/paginate).
- FormRequests with validation rules; consistent JSON envelope via base ApiController.
- Models: User, UserProfile, UserHealthProfile, Food, FoodNutrition, GlucoseReading, MealPlan, PlannedMeal (+ relationships, casts, policy hooks).
- Migrations: users/profile/health, foods + nutrition + sources + translations + allergens + availability, glucose_readings, hba1c_results, meal plans trio, seasonal_food_calendars, audit_logs.
- Seeders: reference data (countries, allergies, dietary preferences, goals) + `DevFoodSeeder` — small PK/UK/US food set, **every row `data_quality_status = 'dev_seed'`**, nutrient values from USDA FoodData Central-style per-100 g figures with the source recorded; values must be re-verified before production (`food_sources` row says so).
- Feature tests: registration/login, glucose unit conversion round-trip.

### Admin (Next.js skeleton)
- App Router project with Tailwind, login page (posts to backend admin auth — endpoint stubbed), dashboard layout + overview page that fetches real stats endpoint and shows explicit "backend not connected" state instead of fake numbers.

### Infrastructure & docs
- docker-compose (Postgres 16, Redis 7, backend, admin, nginx), Dockerfiles, nginx dev config.
- Architecture overview, DB schema doc, API contract doc, security architecture, nutrition safety checklist, design system doc.

## Pending configuration (documented adapters / stubs — NOT functional yet)
- Google Sign-In & Apple Sign In (interface + TODO markers; needs OAuth client IDs / Apple keys).
- Firebase Cloud Messaging / APNs (NotificationGateway interface, LogOnly dev adapter).
- AI provider (AiGateway interface, `FakeAiGateway` echoes structured stub; needs server-side API key + provider choice).
- Google Play Billing / Apple IAP (entitlement service contract only).
- Email delivery (Laravel log mailer in dev).

## Not yet implemented (later phases)
- Meal-plan generation engine (Phase 3) — schema + API contract ready, generator returns 501 with explanation.
- Meal replacement engine, grocery planner, seasonal engine logic, food scanner, AI chat, subscriptions, PDF reports, offline sync, full admin modules.
- Automated test coverage beyond the foundation tests listed above.
- Any clinical/dietitian review — **required before shipping health messaging**.

## Known blockers / risks
1. Flutter/PHP toolchains were not executed in this build environment; run `flutter analyze`, `flutter test`, `composer install && php artisan test` locally — expect minor fixes typical of first compile.
2. Verified nutrition data licensing + ingestion pipeline (USDA FDC import job) is a Phase 3 prerequisite.
3. Qualified medical review of safety copy is unresolved by design at this stage.
