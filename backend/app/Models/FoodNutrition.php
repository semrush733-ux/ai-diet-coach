<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Per-100 g/ml values. Nullable columns stay null when a source does not
 * provide a value — nutrient data is never fabricated.
 */
class FoodNutrition extends Model
{
    protected $table = 'food_nutrition';

    protected $fillable = [
        'food_id', 'calories_kcal', 'carbs_g', 'fiber_g',
        'protein_g', 'fat_g', 'sodium_mg', 'version', 'food_source_id',
    ];

    public function source(): BelongsTo
    {
        return $this->belongsTo(FoodSource::class, 'food_source_id');
    }
}
