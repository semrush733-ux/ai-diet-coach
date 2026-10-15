# AI Diet Coach — Laravel backend

```bash
composer install
cp .env.example .env
php artisan key:generate
createdb ai_diet_coach           # or use docker compose postgres
php artisan migrate --seed       # seeds reference data + DEV SEED foods
php artisan serve                # http://127.0.0.1:8000  (API at /api/v1)

# Tests (needs an ai_diet_coach_test Postgres DB):
createdb ai_diet_coach_test
php artisan test
```

Dev seed foods are flagged `data_quality_status = dev_seed` and must be
re-verified against licensed sources before production.
