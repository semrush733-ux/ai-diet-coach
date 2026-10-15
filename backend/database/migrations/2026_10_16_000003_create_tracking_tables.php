<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('glucose_readings', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('value_original', 6, 2);
            $table->string('unit_original', 8); // mg_dl | mmol_l — source unit kept
            $table->decimal('value_mg_dl', 6, 2); // canonical
            $table->string('context', 24);
            $table->timestampTz('measured_at');
            $table->unsignedSmallInteger('minutes_since_meal')->nullable();
            $table->string('note', 500)->nullable();
            $table->string('source', 16)->default('manual');
            $table->timestampsTz();
            $table->index(['user_id', 'measured_at']);
        });

        Schema::create('hba1c_results', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('value_percent', 4, 1);
            $table->date('tested_at');
            $table->string('lab_name', 160)->nullable();
            $table->string('note', 500)->nullable();
            $table->timestampsTz();
            $table->index(['user_id', 'tested_at']);
        });

        Schema::create('weight_records', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('weight_kg', 5, 1);
            $table->timestampTz('recorded_at');
            $table->timestampsTz();
            $table->index(['user_id', 'recorded_at']);
        });

        Schema::create('water_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('amount_ml');
            $table->timestampTz('logged_at');
            $table->timestampsTz();
            $table->index(['user_id', 'logged_at']);
        });

        Schema::create('activity_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 32)->default('walk');
            $table->unsignedSmallInteger('duration_min');
            $table->unsignedInteger('steps')->nullable();
            $table->timestampTz('logged_at');
            $table->timestampsTz();
            $table->index(['user_id', 'logged_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('activity_logs');
        Schema::dropIfExists('water_logs');
        Schema::dropIfExists('weight_records');
        Schema::dropIfExists('hba1c_results');
        Schema::dropIfExists('glucose_readings');
    }
};
