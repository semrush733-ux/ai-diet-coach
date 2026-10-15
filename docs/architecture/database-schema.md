# Database Schema (PostgreSQL) — Phase 1 design

Normalized schema. All timestamps are `timestamptz`. Soft deletes only where noted. FKs are `ON DELETE CASCADE` for owned child rows, `RESTRICT` for reference data.

## Identity & profile

### users
| column | type | notes |
|---|---|---|
| id | bigserial PK | |
| email | citext UNIQUE | |
| password | varchar | hashed, nullable for social-only accounts |
| email_verified_at | timestamptz NULL | |
| google_id / apple_id | varchar NULL, indexed | social auth |
| status | varchar | active / suspended / deletion_requested |
| created_at / updated_at / deleted_at | | soft delete (grace period before purge) |

### user_profiles (1:1 users)
display_name, date_of_birth (date NULL), height_cm numeric(5,1) NULL, weight_kg numeric(5,1) NULL, unit_system (metric/imperial), country_code FK countries, region varchar NULL, timezone varchar, locale varchar, avatar_path varchar NULL.

### user_health_profiles (1:1 users, sensitive — policy-gated)
diabetes_status enum(none, prediabetes, type2, other, unsure, not_disclosed), hba1c_latest numeric(4,1) NULL, glucose_unit (mg_dl/mmol_l), clinician_target_low / clinician_target_high numeric NULL (stored in mg/dL canonical), medication_categories jsonb NULL, requires_clinician_flag boolean default false, notes text NULL.

### user_health_consents
user_id FK, consent_type (health_data_processing, ai_chat_history, analytics), granted boolean, granted_at, revoked_at NULL, version varchar. Append-only.

### health_goals / user_health_goals (M:N)
Reference list (eat_healthier, maintain_weight, manage_weight, meal_consistency, manage_carbs, prediabetes_support, type2_support) + pivot.

### allergies / user_allergies (M:N), dietary_preferences / user_dietary_preferences (M:N), medical_dietary_restrictions / user_medical_dietary_restrictions (M:N)
Reference tables with `code`, `name`; pivots with user_id. Allergy pivot has `severity` (mild/moderate/severe).

### user_schedules (1:1 users)
wake_time, breakfast_time, lunch_time, dinner_time, bed_time (time NULL each), work_start/work_end NULL, meals_per_day smallint, wants_snacks boolean, activity_notes text NULL.

### user_budgets (1:1 users)
budget_tier (budget/balanced/premium/custom), weekly_amount numeric NULL, currency_code char(3).

## Reference / localization
**countries** (iso2 PK-ish unique, name, hemisphere, default_currency), **regions** (country FK, name), **localization_settings** (locale, enabled, rtl boolean).

## Food system
### foods
id, slug UNIQUE, name, category (fruit/vegetable/grain/protein/dairy/legume/prepared/other), default_serving_size numeric, serving_unit (g/ml/piece/cup/tbsp/tsp), image_path NULL, is_halal_suitable boolean NULL, is_vegetarian boolean NULL, is_vegan boolean NULL, data_quality_status enum(**dev_seed**, pending_review, verified, estimated, missing), last_verified_at NULL, soft deletes.

### food_translations
food_id FK, locale, name, UNIQUE(food_id, locale).

### food_nutrition (per 100 g/ml canonical)
food_id FK UNIQUE-with-version, calories_kcal, carbs_g, fiber_g, protein_g, fat_g, sodium_mg — **each numeric NULL** (missing stays NULL, never fabricated), version int, source_id FK food_sources.

### food_sources
name (e.g. "USDA FoodData Central"), reference (FDC ID/URL), retrieved_at, license_note.

### food_allergens (M:N foods↔allergies), food_country_availability (M:N foods↔countries)

### recipes / recipe_ingredients / recipe_nutrition
recipes: name, cuisine, country_code NULL, prep_minutes, instructions text, image_path, dietary flags, data_quality_status. recipe_ingredients: recipe_id, food_id, quantity, unit, note. recipe_nutrition: computed totals + per-serving, version, computed_at (always derived from ingredients — deterministic job, never hand-entered).

### seasonal_food_calendars
country_code, region NULL, food_id, month smallint (1-12), availability (peak/available/limited), source varchar, verification_status (pending/verified), UNIQUE(country, region, food, month).

## Planning
### meal_plan_templates
name, description, dietary_category, region scope, status (draft/in_review/approved), version int, reviewed_by admin FK NULL, reviewed_at NULL.

### meal_plans
user_id, start_date, end_date, status (active/superseded/archived), generation_inputs jsonb (snapshot of profile inputs used — transparency), version int.

### meal_plan_days (plan FK, date) → planned_meals
planned_meals: day FK, meal_type (breakfast/morning_snack/lunch/afternoon_snack/dinner/extra), scheduled_time, recipe_id NULL, food_id NULL, serving_multiplier numeric default 1, status (planned/eaten/skipped/replaced), completed_at NULL, nutrition_snapshot jsonb (frozen computed values at generation time with provenance).

### meal_replacements
planned_meal_id, previous_recipe/food refs, new refs, delta jsonb (kcal/carb/protein differences — computed), reason, created_at. Versioned history.

## Diary & tracking
**food_diary_entries** (user, date, meal_type, source enum(plan/manual/scanner)), **consumed_food_items** (entry FK, food/recipe FK, quantity, unit, nutrition_snapshot jsonb).

### glucose_readings
user_id, value_original numeric(6,2), unit_original (mg_dl/mmol_l), **value_mg_dl numeric(6,2)** canonical, context enum(fasting, before_breakfast, after_breakfast, before_lunch, after_lunch, before_dinner, after_dinner, bedtime, random, other), minutes_since_meal int NULL, note text NULL, source (manual/import), measured_at timestamptz, indexes (user_id, measured_at).

### hba1c_results
user_id, value_percent numeric(4,1), tested_at date, lab_name NULL, note NULL.

**weight_records** (user, weight_kg, recorded_at), **water_logs** (user, amount_ml, logged_at), **activity_logs** (user, type, duration_min, steps NULL, logged_at).

## Reminders & notifications
**medications** (user, name, category, schedule jsonb — user-entered, app never infers doses), **medication_reminders**, **notifications** (user, type, title, body, scheduled_for, sent_at NULL, read_at NULL), **device_tokens** (user, platform, token UNIQUE, last_seen_at).

## AI
**ai_conversations** (user, title, consent_version, created_at), **ai_messages** (conversation FK, role, content, tool_calls jsonb NULL, safety_flags jsonb NULL), **ai_usage_logs** (user NULL, endpoint, provider, tokens_in/out, cost_estimate, latency_ms, status). PII minimized in usage logs.

## Billing
**subscriptions** (user, plan_code, store enum(google/apple/none), store_product_id, status enum(active/grace/expired/revoked/cancelled), current_period_end, auto_renew boolean), **subscription_transactions** (subscription FK, store_transaction_id UNIQUE — idempotency, payload jsonb, verified_at), **payment_entitlements** (user, entitlement_code, granted_via, expires_at NULL).

## Support, safety, admin
**support_tickets** (+status/priority/category, internal notes table), **content_reviews** (reviewable morph, reviewer admin FK, decision, notes), **safety_rule_versions** (rule_code, version, locale, content jsonb, status draft/approved, approved_by, approved_at), **admin_roles** / **admin_permissions** / pivots, **audit_logs** (actor morph, action, target morph, metadata jsonb, ip, created_at — append-only), **data_export_requests**, **account_deletion_requests** (status, scheduled_purge_at).

## Idempotency & integrity notes
- Payment webhooks and notification events dedupe on store/event IDs (UNIQUE constraints).
- Nutrition snapshots in planned meals/diary freeze values with source provenance so later food-data corrections don't silently rewrite history (a correction creates a new food_nutrition version).
- All user-health tables accessed exclusively through Laravel policies; admin access requires explicit `health.read` permission and writes an audit_log row.
