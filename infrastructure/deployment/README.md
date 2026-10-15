# Deployment notes (Phase 1)

- `docker compose up -d` at repo root starts Postgres, Redis, backend, admin, nginx (dev).
- Production: use `nginx/prod.conf.template`, managed Postgres with automated backups,
  `php artisan queue:work` + `schedule:run` under a supervisor, and object storage for uploads.
- CI/CD, monitoring (Sentry-compatible), and backup drills are Phase 2+ tasks —
  see docs/architecture/implementation-status.md.
