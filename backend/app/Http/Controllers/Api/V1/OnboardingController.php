<?php

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class OnboardingController extends ApiController
{
    /**
     * Persists the full onboarding wizard atomically.
     */
    public function complete(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'profile.display_name' => ['required', 'string', 'max:120'],
            'profile.age' => ['nullable', 'integer', 'between:18,120'],
            'profile.height_cm' => ['nullable', 'numeric', 'between:50,272'],
            'profile.weight_kg' => ['nullable', 'numeric', 'between:20,500'],
            'profile.unit_system' => ['required', Rule::in(['metric', 'imperial'])],
            'profile.country_code' => ['required', 'string', 'size:2'],
            'goals' => ['required', 'array', 'min:1'],
            'goals.*' => ['string', 'max:64'],
            'health.diabetes_status' => ['required', Rule::in([
                'none', 'prediabetes', 'type2', 'other', 'unsure', 'not_disclosed',
            ])],
            'health.glucose_unit' => ['required', Rule::in(['mg_dl', 'mmol_l'])],
            'dietary_preferences' => ['array'],
            'dietary_preferences.*' => ['string', 'max:64'],
            'allergies' => ['array'],
            'allergies.*' => ['string', 'max:64'],
            'schedule.wake_time' => ['required', 'date_format:H:i'],
            'schedule.breakfast_time' => ['required', 'date_format:H:i'],
            'schedule.lunch_time' => ['required', 'date_format:H:i'],
            'schedule.dinner_time' => ['required', 'date_format:H:i'],
            'schedule.bed_time' => ['required', 'date_format:H:i'],
            'schedule.wants_snacks' => ['required', 'boolean'],
            'budget.tier' => ['required', Rule::in(['budget', 'balanced', 'premium', 'custom'])],
        ]);

        $user = $request->user();

        DB::transaction(function () use ($user, $validated): void {
            $user->profile()->updateOrCreate([], [
                'display_name' => $validated['profile']['display_name'],
                'height_cm' => $validated['profile']['height_cm'] ?? null,
                'weight_kg' => $validated['profile']['weight_kg'] ?? null,
                'unit_system' => $validated['profile']['unit_system'],
                'country_code' => strtoupper($validated['profile']['country_code']),
            ]);

            $user->healthProfile()->updateOrCreate([], [
                'diabetes_status' => $validated['health']['diabetes_status'],
                'glucose_unit' => $validated['health']['glucose_unit'],
                'requires_clinician_flag' => $validated['health']['diabetes_status'] === 'other',
            ]);

            $user->schedule()->updateOrCreate([], [
                'wake_time' => $validated['schedule']['wake_time'],
                'breakfast_time' => $validated['schedule']['breakfast_time'],
                'lunch_time' => $validated['schedule']['lunch_time'],
                'dinner_time' => $validated['schedule']['dinner_time'],
                'bed_time' => $validated['schedule']['bed_time'],
                'wants_snacks' => $validated['schedule']['wants_snacks'],
            ]);

            $user->budget()->updateOrCreate([], [
                'budget_tier' => $validated['budget']['tier'],
            ]);

            // Goals / preferences / allergies as code arrays on pivot-ready
            // JSON columns for Phase 1; normalized pivots land in Phase 2.
            $user->profile()->update([
                'goal_codes' => $validated['goals'],
                'dietary_preference_codes' => $validated['dietary_preferences'] ?? [],
                'allergy_codes' => $validated['allergies'] ?? [],
            ]);

            $user->forceFill(['onboarded_at' => now()])->save();
        });

        return $this->success(['onboarded' => true], status: 201);
    }
}
