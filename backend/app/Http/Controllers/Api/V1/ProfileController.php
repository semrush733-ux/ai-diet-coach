<?php

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProfileController extends ApiController
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user()->load('profile');
        $profile = $user->profile;

        return $this->success([
            'id' => $user->id,
            'email' => $user->email,
            'display_name' => $profile?->display_name ?? '',
            'email_verified' => $user->hasVerifiedEmail(),
            'onboarded' => $user->onboarded_at !== null,
            'unit_system' => $profile?->unit_system ?? 'metric',
            'country_code' => $profile?->country_code,
            'locale' => $profile?->locale ?? 'en',
            'timezone' => $profile?->timezone ?? 'UTC',
            'height_cm' => $profile?->height_cm,
            'weight_kg' => $profile?->weight_kg,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'display_name' => ['sometimes', 'string', 'max:120'],
            'height_cm' => ['sometimes', 'nullable', 'numeric', 'between:50,272'],
            'weight_kg' => ['sometimes', 'nullable', 'numeric', 'between:20,500'],
            'unit_system' => ['sometimes', Rule::in(['metric', 'imperial'])],
            'country_code' => ['sometimes', 'string', 'size:2'],
            'timezone' => ['sometimes', 'string', 'max:64'],
            'locale' => ['sometimes', 'string', 'max:10'],
        ]);

        $profile = $request->user()->profile()->firstOrCreate([]);
        $profile->fill($validated)->save();

        return $this->show($request);
    }

    public function showHealth(Request $request): JsonResponse
    {
        $health = $request->user()->healthProfile;

        return $this->success([
            'diabetes_status' => $health?->diabetes_status ?? 'not_disclosed',
            'glucose_unit' => $health?->glucose_unit ?? 'mg_dl',
            'clinician_target_low_mg_dl' => $health?->clinician_target_low_mg_dl,
            'clinician_target_high_mg_dl' => $health?->clinician_target_high_mg_dl,
            'requires_clinician_flag' => (bool) ($health?->requires_clinician_flag ?? false),
        ]);
    }

    public function updateHealth(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'diabetes_status' => ['sometimes', Rule::in([
                'none', 'prediabetes', 'type2', 'other', 'unsure', 'not_disclosed',
            ])],
            'glucose_unit' => ['sometimes', Rule::in(['mg_dl', 'mmol_l'])],
        ]);

        $health = $request->user()->healthProfile()->firstOrCreate([]);

        // Conditions outside general-purpose templates are flagged for
        // clinician-guided planning — never auto-handled.
        if (($validated['diabetes_status'] ?? null) === 'other') {
            $health->requires_clinician_flag = true;
        }

        $health->fill($validated)->save();

        return $this->showHealth($request);
    }
}
