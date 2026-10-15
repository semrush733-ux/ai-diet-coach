<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('meal_plans', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('start_date');
            $table->date('end_date');
            $table->string('status', 16)->default('active'); // active|superseded|archived
            // Snapshot of inputs used for generation — transparency to the user.
            $table->jsonb('generation_inputs')->nullable();
            $table->unsignedInteger('version')->default(1);
            $table->timestampsTz();
            $table->index(['user_id', 'status', 'start_date']);
        });

        Schema::create('meal_plan_days', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('meal_plan_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->timestampsTz();
            $table->unique(['meal_plan_id', 'date']);
        });

        Schema::create('planned_meals', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('meal_plan_day_id')->constrained()->cascadeOnDelete();
            $table->string('meal_type', 24);
            $table->string('title');
            $table->timestampTz('scheduled_at')->nullable();
            $table->foreignId('food_id')->nullable()->constrained()->restrictOnDelete();
            $table->unsignedBigInteger('recipe_id')->nullable(); // FK added with recipes (Phase 3)
            $table->decimal('serving_multiplier', 5, 2)->default(1);
            $table->string('serving_label', 120)->nullable();
            $table->string('status', 16)->default('planned'); // planned|eaten|skipped|replaced
            $table->timestampTz('completed_at')->nullable();
            // Frozen computed values + provenance; corrections create new
            // food_nutrition versions and never rewrite history silently.
            $table->jsonb('nutrition_snapshot')->nullable();
            $table->timestampsTz();
            $table->index(['meal_plan_day_id', 'scheduled_at']);
        });

        Schema::create('meal_replacements', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('planned_meal_id')->constrained()->cascadeOnDelete();
            $table->jsonb('previous');
            $table->jsonb('replacement');
            $table->jsonb('delta')->nullable(); // computed kcal/carb/protein diff
            $table->string('reason', 160)->nullable();
            $table->timestampsTz();
        });

        // Append-only: admin actions and sensitive-data access.
        Schema::create('audit_logs', function (Blueprint $table): void {
            $table->id();
            $table->string('actor_type', 64);
            $table->unsignedBigInteger('actor_id');
            $table->string('action', 80);
            $table->string('target_type', 64)->nullable();
            $table->unsignedBigInteger('target_id')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->string('ip', 45)->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->index(['actor_type', 'actor_id']);
            $table->index(['target_type', 'target_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('meal_replacements');
        Schema::dropIfExists('planned_meals');
        Schema::dropIfExists('meal_plan_days');
        Schema::dropIfExists('meal_plans');
    }
};
