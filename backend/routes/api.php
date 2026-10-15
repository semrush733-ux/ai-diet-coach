<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\FoodController;
use App\Http\Controllers\Api\V1\GlucoseReadingController;
use App\Http\Controllers\Api\V1\HbA1cController;
use App\Http\Controllers\Api\V1\MealPlanController;
use App\Http\Controllers\Api\V1\OnboardingController;
use App\Http\Controllers\Api\V1\ProfileController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API v1
|--------------------------------------------------------------------------
| Envelope: { data, meta } on success — { error: { code, message, details } }
| on failure. See docs/api/api-contract-v1.md.
*/

Route::prefix('v1')->group(function (): void {

    // ── Public auth (tight throttle, no enumeration) ──────────────────
    Route::middleware('throttle:10,1')->prefix('auth')->group(function (): void {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
        Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    });

    // ── Authenticated ─────────────────────────────────────────────────
    Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function (): void {
        Route::post('auth/logout', [AuthController::class, 'logout']);

        // Profile & onboarding
        Route::get('profile', [ProfileController::class, 'show']);
        Route::patch('profile', [ProfileController::class, 'update']);
        Route::get('health-profile', [ProfileController::class, 'showHealth']);
        Route::patch('health-profile', [ProfileController::class, 'updateHealth']);
        Route::post('onboarding/complete', [OnboardingController::class, 'complete']);

        // Foods (verified database, read-only for users)
        Route::get('foods', [FoodController::class, 'index']);
        Route::get('foods/{food}', [FoodController::class, 'show']);

        // Meal plans — generation lands in Phase 3; endpoints return 501
        // with a clear explanation until then (never fake data).
        Route::post('meal-plans/generate', [MealPlanController::class, 'generate']);
        Route::get('meal-plans/today', [MealPlanController::class, 'today']);

        // Glucose
        Route::get('glucose-readings', [GlucoseReadingController::class, 'index']);
        Route::post('glucose-readings', [GlucoseReadingController::class, 'store']);
        Route::patch('glucose-readings/{glucoseReading}', [GlucoseReadingController::class, 'update']);
        Route::delete('glucose-readings/{glucoseReading}', [GlucoseReadingController::class, 'destroy']);

        // HbA1c
        Route::get('hba1c', [HbA1cController::class, 'index']);
        Route::post('hba1c', [HbA1cController::class, 'store']);
    });
});
