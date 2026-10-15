<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Food;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FoodController extends ApiController
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'query' => ['sometimes', 'string', 'max:120'],
            'country' => ['sometimes', 'string', 'size:2'],
            'category' => ['sometimes', Rule::in([
                'fruit', 'vegetable', 'grain', 'protein', 'dairy', 'legume', 'prepared', 'other',
            ])],
            'vegetarian' => ['sometimes', 'boolean'],
            'halal' => ['sometimes', 'boolean'],
            'max_kcal' => ['sometimes', 'numeric', 'gt:0'],
            'max_carbs_g' => ['sometimes', 'numeric', 'gte:0'],
            'per_page' => ['sometimes', 'integer', 'between:1,50'],
        ]);

        $query = Food::query()->with('nutrition')->orderBy('name');

        if (isset($validated['query'])) {
            $query->where('name', 'ilike', '%'.$validated['query'].'%');
        }
        if (isset($validated['country'])) {
            $query->whereHas('countries', fn ($q) => $q->where('iso2', strtoupper($validated['country'])));
        }
        if (isset($validated['category'])) {
            $query->where('category', $validated['category']);
        }
        if (($validated['vegetarian'] ?? null) === true) {
            $query->where('is_vegetarian', true);
        }
        if (($validated['halal'] ?? null) === true) {
            $query->where('is_halal_suitable', true);
        }
        if (isset($validated['max_kcal'])) {
            $query->whereHas('nutrition', fn ($q) => $q->where('calories_kcal', '<=', $validated['max_kcal']));
        }
        if (isset($validated['max_carbs_g'])) {
            $query->whereHas('nutrition', fn ($q) => $q->where('carbs_g', '<=', $validated['max_carbs_g']));
        }

        $page = $query->paginate($validated['per_page'] ?? 20);

        return $this->success(
            collect($page->items())->map(fn (Food $f) => $this->payload($f)),
            [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
            ],
        );
    }

    public function show(Food $food): JsonResponse
    {
        $food->load(['nutrition.source']);

        return $this->success($this->payload($food, detailed: true));
    }

    private function payload(Food $food, bool $detailed = false): array
    {
        $n = $food->nutrition;

        $base = [
            'id' => $food->id,
            'slug' => $food->slug,
            'name' => $food->name,
            'category' => $food->category,
            'default_serving_size' => (float) $food->default_serving_size,
            'serving_unit' => $food->serving_unit,
            'is_halal_suitable' => $food->is_halal_suitable,
            'is_vegetarian' => $food->is_vegetarian,
            'is_vegan' => $food->is_vegan,
            'data_quality_status' => $food->data_quality_status,
            // Missing values stay null — never fabricated.
            'nutrition_per_100' => $n === null ? null : [
                'calories_kcal' => $n->calories_kcal !== null ? (float) $n->calories_kcal : null,
                'carbs_g' => $n->carbs_g !== null ? (float) $n->carbs_g : null,
                'fiber_g' => $n->fiber_g !== null ? (float) $n->fiber_g : null,
                'protein_g' => $n->protein_g !== null ? (float) $n->protein_g : null,
                'fat_g' => $n->fat_g !== null ? (float) $n->fat_g : null,
                'sodium_mg' => $n->sodium_mg !== null ? (float) $n->sodium_mg : null,
            ],
        ];

        if ($detailed) {
            $base['source'] = $n?->source === null ? null : [
                'name' => $n->source->name,
                'reference' => $n->source->reference,
                'retrieved_at' => $n->source->retrieved_at?->toDateString(),
            ];
        }

        return $base;
    }
}
