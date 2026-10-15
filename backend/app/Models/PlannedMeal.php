<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlannedMeal extends Model
{
    protected $fillable = [
        'meal_plan_day_id', 'meal_type', 'title', 'scheduled_at',
        'recipe_id', 'food_id', 'serving_multiplier', 'serving_label',
        'status', 'completed_at', 'nutrition_snapshot',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'completed_at' => 'datetime',
            'serving_multiplier' => 'decimal:2',
            'nutrition_snapshot' => 'array',
        ];
    }
}
