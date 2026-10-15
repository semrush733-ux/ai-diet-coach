<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->string('email')->unique();
            $table->string('password')->nullable(); // nullable for social-only
            $table->timestampTz('email_verified_at')->nullable();
            $table->string('google_id')->nullable()->index();
            $table->string('apple_id')->nullable()->index();
            $table->string('status', 32)->default('active');
            $table->timestampTz('onboarded_at')->nullable();
            $table->rememberToken();
            $table->timestampsTz();
            $table->softDeletesTz();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table): void {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestampTz('created_at')->nullable();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table): void {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestampTz('last_used_at')->nullable();
            $table->timestampTz('expires_at')->nullable();
            $table->timestampsTz();
        });

        Schema::create('countries', function (Blueprint $table): void {
            $table->id();
            $table->char('iso2', 2)->unique();
            $table->string('name');
            $table->string('hemisphere', 16)->default('northern');
            $table->char('default_currency', 3)->nullable();
            $table->timestampsTz();
        });

        Schema::create('user_profiles', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('display_name', 120)->default('');
            $table->date('date_of_birth')->nullable();
            $table->decimal('height_cm', 5, 1)->nullable();
            $table->decimal('weight_kg', 5, 1)->nullable();
            $table->string('unit_system', 16)->default('metric');
            $table->char('country_code', 2)->nullable()->index();
            $table->string('region', 120)->nullable();
            $table->string('timezone', 64)->default('UTC');
            $table->string('locale', 10)->default('en');
            $table->string('avatar_path')->nullable();
            // Phase 1: code arrays; Phase 2 normalizes into pivot tables.
            $table->jsonb('goal_codes')->default('[]');
            $table->jsonb('dietary_preference_codes')->default('[]');
            $table->jsonb('allergy_codes')->default('[]');
            $table->timestampsTz();
        });

        // Sensitive — policy-gated; admin access audited.
        Schema::create('user_health_profiles', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('diabetes_status', 24)->default('not_disclosed');
            $table->string('glucose_unit', 8)->default('mg_dl');
            $table->decimal('clinician_target_low_mg_dl', 6, 1)->nullable();
            $table->decimal('clinician_target_high_mg_dl', 6, 1)->nullable();
            $table->jsonb('medication_categories')->nullable();
            $table->boolean('requires_clinician_flag')->default(false);
            $table->text('notes')->nullable();
            $table->timestampsTz();
        });

        Schema::create('user_schedules', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->time('wake_time')->nullable();
            $table->time('breakfast_time')->nullable();
            $table->time('lunch_time')->nullable();
            $table->time('dinner_time')->nullable();
            $table->time('bed_time')->nullable();
            $table->boolean('wants_snacks')->default(true);
            $table->timestampsTz();
        });

        Schema::create('user_budgets', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('budget_tier', 16)->default('balanced');
            $table->decimal('weekly_amount', 10, 2)->nullable();
            $table->char('currency_code', 3)->nullable();
            $table->timestampsTz();
        });

        Schema::create('user_health_consents', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('consent_type', 48);
            $table->boolean('granted');
            $table->timestampTz('granted_at');
            $table->timestampTz('revoked_at')->nullable();
            $table->string('version', 16);
            $table->timestampsTz();
            $table->index(['user_id', 'consent_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_health_consents');
        Schema::dropIfExists('user_budgets');
        Schema::dropIfExists('user_schedules');
        Schema::dropIfExists('user_health_profiles');
        Schema::dropIfExists('user_profiles');
        Schema::dropIfExists('countries');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
