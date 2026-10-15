<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\GlucoseReading;
use App\Services\GlucoseUnitConverter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class GlucoseReadingController extends ApiController
{
    private const CONTEXTS = [
        'fasting', 'before_breakfast', 'after_breakfast', 'before_lunch',
        'after_lunch', 'before_dinner', 'after_dinner', 'bedtime',
        'random', 'other',
    ];

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'from' => ['sometimes', 'date'],
            'to' => ['sometimes', 'date'],
            'context' => ['sometimes', Rule::in(self::CONTEXTS)],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = $request->user()->glucoseReadings()->orderByDesc('measured_at');

        if (isset($validated['from'])) {
            $query->where('measured_at', '>=', $validated['from']);
        }
        if (isset($validated['to'])) {
            $query->where('measured_at', '<=', $validated['to']);
        }
        if (isset($validated['context'])) {
            $query->where('context', $validated['context']);
        }

        $page = $query->paginate($validated['per_page'] ?? 30);

        return $this->success(
            collect($page->items())->map(fn (GlucoseReading $r) => $this->payload($r)),
            [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
            ],
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'value' => ['required', 'numeric', 'gt:0'],
            'unit' => ['required', Rule::in(['mg_dl', 'mmol_l'])],
            'context' => ['required', Rule::in(self::CONTEXTS)],
            'measured_at' => ['required', 'date'],
            'minutes_since_meal' => ['sometimes', 'nullable', 'integer', 'between:0,1440'],
            'note' => ['sometimes', 'nullable', 'string', 'max:500'],
        ]);

        // Plausibility bounds per unit (reject typos like 55 mmol/L).
        $max = $validated['unit'] === 'mg_dl' ? 1000 : 55.5;
        if ((float) $validated['value'] > $max) {
            return $this->failure('validation_error', 'The glucose value is outside the accepted range for the selected unit.', 422, [
                'value' => ['The glucose value is outside the accepted range for the selected unit.'],
            ]);
        }

        $reading = $request->user()->glucoseReadings()->create([
            'value_original' => $validated['value'],
            'unit_original' => $validated['unit'],
            'value_mg_dl' => GlucoseUnitConverter::toMgDl((float) $validated['value'], $validated['unit']),
            'context' => $validated['context'],
            'measured_at' => $validated['measured_at'],
            'minutes_since_meal' => $validated['minutes_since_meal'] ?? null,
            'note' => $validated['note'] ?? null,
            'source' => 'manual',
        ]);

        return $this->success($this->payload($reading), status: 201);
    }

    public function update(Request $request, GlucoseReading $glucoseReading): JsonResponse
    {
        $this->authorizeOwner($request, $glucoseReading);

        $validated = $request->validate([
            'context' => ['sometimes', Rule::in(self::CONTEXTS)],
            'measured_at' => ['sometimes', 'date'],
            'note' => ['sometimes', 'nullable', 'string', 'max:500'],
        ]);

        $glucoseReading->fill($validated)->save();

        return $this->success($this->payload($glucoseReading));
    }

    public function destroy(Request $request, GlucoseReading $glucoseReading): JsonResponse
    {
        $this->authorizeOwner($request, $glucoseReading);
        $glucoseReading->delete();

        return $this->success(null);
    }

    private function authorizeOwner(Request $request, GlucoseReading $reading): void
    {
        abort_if($reading->user_id !== $request->user()->id, 404);
    }

    private function payload(GlucoseReading $r): array
    {
        return [
            'id' => $r->id,
            'value_original' => (float) $r->value_original,
            'unit_original' => $r->unit_original,
            'value_mg_dl' => (float) $r->value_mg_dl,
            'value_mmol_l' => GlucoseUnitConverter::toMmolL((float) $r->value_mg_dl),
            'context' => $r->context,
            'measured_at' => $r->measured_at?->toIso8601String(),
            'minutes_since_meal' => $r->minutes_since_meal,
            'note' => $r->note,
            'source' => $r->source,
        ];
    }
}
