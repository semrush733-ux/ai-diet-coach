<?php

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HbA1cController extends ApiController
{
    public function index(Request $request): JsonResponse
    {
        $results = $request->user()->hba1cResults()
            ->orderByDesc('tested_at')
            ->limit(100)
            ->get()
            ->map(fn ($r) => [
                'id' => $r->id,
                'value_percent' => (float) $r->value_percent,
                'tested_at' => $r->tested_at->toDateString(),
                'lab_name' => $r->lab_name,
                'note' => $r->note,
            ]);

        return $this->success($results);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'value_percent' => ['required', 'numeric', 'between:3,20'],
            'tested_at' => ['required', 'date', 'before_or_equal:today'],
            'lab_name' => ['sometimes', 'nullable', 'string', 'max:160'],
            'note' => ['sometimes', 'nullable', 'string', 'max:500'],
        ]);

        $result = $request->user()->hba1cResults()->create($validated);

        return $this->success([
            'id' => $result->id,
            'value_percent' => (float) $result->value_percent,
            'tested_at' => $result->tested_at->toDateString(),
            'lab_name' => $result->lab_name,
            'note' => $result->note,
        ], status: 201);
    }
}
