<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MealPlanDay extends Model
{
    protected $fillable = ['meal_plan_id', 'date'];

    protected function casts(): array
    {
        return ['date' => 'date'];
    }

    public function meals(): HasMany
    {
        return $this->hasMany(PlannedMeal::class)->orderBy('scheduled_at');
    }
}
