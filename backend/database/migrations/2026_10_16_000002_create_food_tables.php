<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('food_sources', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('reference')->nullable();
            $table->date('retrieved_at')->nullable();
            $table->text('license_note')->nullable();
            $table->timestampsTz();
        });

        Schema::create('foods', function (Blueprint $table): void {
            $table->id();
            $table->string('slug')->unique();
            $table->string('name');
            $table->string('category', 24)->index();
            $table->decimal('default_serving_size', 7, 1)->default(100);
            $table->string('serving_unit', 16)->default('g');
            $table->string('image_path')->nullable();
            $table->boolean('is_halal_suitable')->nullable();
            $table->boolean('is_vegetarian')->nullable();
            $table->boolean('is_vegan')->nullable();
            // dev_seed | pending_review | verified | estimated | missing
            $table->string('data_quality_status', 24)->default('pending_review')->index();
            $table->timestampTz('last_verified_at')->nullable();
            $table->timestampsTz();
            $table->softDeletesTz();
        });

        Schema::create('food_translations', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('food_id')->constrained()->cascadeOnDelete();
            $table->string('locale', 10);
            $table->string('name');
            $table->unique(['food_id', 'locale']);
            $table->timestampsTz();
        });

        // Per 100 g/ml. Nullable = source did not provide → stays null.
        Schema::create('food_nutrition', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('food_id')->constrained()->cascadeOnDelete();
            $table->decimal('calories_kcal', 7, 1)->nullable();
            $table->decimal('carbs_g', 6, 2)->nullable();
            $table->decimal('fiber_g', 6, 2)->nullable();
            $table->decimal('protein_g', 6, 2)->nullable();
            $table->decimal('fat_g', 6, 2)->nullable();
            $table->decimal('sodium_mg', 8, 1)->nullable();
            $table->unsignedInteger('version')->default(1);
            $table->foreignId('food_source_id')->nullable()->constrained('food_sources')->restrictOnDelete();
            $table->timestampsTz();
            $table->unique(['food_id', 'version']);
        });

        Schema::create('allergies', function (Blueprint $table): void {
            $table->id();
            $table->string('code', 48)->unique();
            $table->string('name');
            $table->timestampsTz();
        });

        Schema::create('food_allergens', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('food_id')->constrained()->cascadeOnDelete();
            $table->foreignId('allergy_id')->constrained()->cascadeOnDelete();
            $table->unique(['food_id', 'allergy_id']);
        });

        Schema::create('food_country_availability', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('food_id')->constrained()->cascadeOnDelete();
            $table->foreignId('country_id')->constrained()->cascadeOnDelete();
            $table->unique(['food_id', 'country_id']);
        });

        Schema::create('seasonal_food_calendars', function (Blueprint $table): void {
            $table->id();
            $table->char('country_code', 2)->index();
            $table->string('region', 120)->nullable();
            $table->foreignId('food_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('month'); // 1-12
            $table->string('availability', 16)->default('available'); // peak|available|limited
            $table->string('source')->nullable();
            $table->string('verification_status', 16)->default('pending');
            $table->timestampsTz();
            $table->unique(['country_code', 'region', 'food_id', 'month']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seasonal_food_calendars');
        Schema::dropIfExists('food_country_availability');
        Schema::dropIfExists('food_allergens');
        Schema::dropIfExists('allergies');
        Schema::dropIfExists('food_nutrition');
        Schema::dropIfExists('food_translations');
        Schema::dropIfExists('foods');
        Schema::dropIfExists('food_sources');
    }
};
