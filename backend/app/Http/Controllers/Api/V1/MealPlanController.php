<?php

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MealPlanController extends ApiController
{
    /**
     * Contracted for Phase 3. Honest 501 until the hybrid planning engine
     * (verified DB → deterministic rules → AI layer → validation gate)
     * is implemented and tested — never a fabricated plan.
     */
    public function generate(Request $request): JsonResponse
    {
        $request->validate([
            'duration' => ['required', Rule::in(['today', 'tomorrow', '3d', '7d', '14d', '30d'])],
        ]);

        return $this->notImplemented(
            'Meal plan generation arrives in Phase 3. Your profile is saved and will be used when the planning engine ships.',
        );
    }

    public function today(Request $request): JsonResponse
    {
        $plan = $request->user()->mealPlans()
            ->where('status', 'active')
            ->whereDate('start_date', '<=', today())
            ->whereDate('end_date', '>=', today())
            ->with(['days' => fn ($q) => $q->whereDate('date', today())->with('meals')])
            ->first();

        $day = $plan?->days->first();

        if ($day === null) {
            return $this->failure('not_found', 'No meal plan exists for today yet.', 404);
        }

        return $this->success([
            'date' => $day->date->toDateString(),
            'meals' => $day->meals->map(fn ($m) => [
                'id' => $m->id,
                'meal_type' => $m->meal_type,
                'title' => $m->title,
                'status' => $m->status,
                'scheduled_at' => $m->scheduled_at?->toIso8601String(),
                'serving_label' => $m->serving_label,
                'nutrition_snapshot' => $m->nutrition_snapshot,
            ])->values(),
        ]);
    }
}
