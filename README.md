# AI Diet Coach

**Eat Smart. Live Better.**

A worldwide smart nutrition and diabetes companion: personalized daily diet plans, regional food options, seasonal produce guidance, blood glucose tracking, and an AI nutrition assistant.

> **Status: Phase 1 — Design System & Architecture foundation.**
> This repository contains the real project scaffolding: Flutter app foundation (design system, navigation, auth + onboarding + home screens), Laravel backend skeleton (API v1, migrations, seeders, auth), Next.js admin shell, Docker infrastructure, and architecture docs.
> It is **not** production-ready. See `docs/architecture/implementation-status.md` for the honest list of what is implemented, what is pending configuration, and known blockers.

---

## Monorepo layout

```
ai-diet-coach/
  mobile/           Flutter app (Android + iOS)
  backend/          Laravel 11 API (PHP 8.3, PostgreSQL, Redis, Sanctum)
  admin/            Next.js + TypeScript + Tailwind admin dashboard
  infrastructure/   Docker, Nginx
  docs/             Architecture, API, design, nutrition safety, security
```

## Tech stack

| Layer | Technology |
|---|---|
| Mobile | Flutter, Riverpod, GoRouter, Dio, flutter_secure_storage, intl/l10n |
| Backend | Laravel 11, PHP 8.3, PostgreSQL 16, Redis 7, Sanctum, queues/scheduler |
| Admin | Next.js 14 (App Router), TypeScript, Tailwind CSS |
| Infra | Docker Compose, Nginx |
| AI | Backend AI gateway (provider-agnostic), deterministic meal rules + verified food DB |

## Quick start (development)

### Prerequisites
- Flutter SDK ≥ 3.22, Dart ≥ 3.4
- PHP 8.3 + Composer 2
- Node.js ≥ 20 + npm
- Docker + Docker Compose (for Postgres/Redis), or local Postgres 16

### 1. Infrastructure (Postgres + Redis)
```bash
cp .env.example .env
docker compose up -d postgres redis
```

### 2. Backend (Laravel)
```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate --seed      # seeds dev food data (clearly labeled DEV SEED)
php artisan serve               # http://127.0.0.1:8000
```

### 3. Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter gen-l10n
flutter run                     # set API_BASE_URL via --dart-define if not default
# e.g. flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### 4. Admin (Next.js)
```bash
cd admin
npm install
npm run dev                     # http://localhost:3000
```

## Environment configuration

Root `.env.example` documents infrastructure variables. Each sub-project has its own `.env.example`. **No real credentials are committed.** External services (FCM, Apple Sign In, Google Sign-In, AI provider keys, store billing) are stubbed behind documented adapters marked `PENDING CONFIGURATION`.

## Medical safety scope

This software provides nutrition education and planning support. It must not diagnose diseases, prescribe medication, calculate insulin doses, or replace professional medical care. Health-critical messaging requires qualified medical review before any production release. See `docs/nutrition/safety-review-checklist.md`.

## Development phases

1. **Phase 1 — Design system & architecture** ← current
2. Phase 2 — Functional foundation (end-to-end auth, profiles, onboarding persistence)
3. Phase 3 — Core Diet Coach MVP (food DB, planner, replacement, seasonal guide)
4. Phase 4 — Diabetes & progress
5. Phase 5 — Advanced AI
6. Phase 6 — Subscriptions
7. Phase 7 — Testing & optimization
8. Phase 8 — Release preparation

## License

Proprietary — BWP Experts. All rights reserved.
