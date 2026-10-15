<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MealPlan extends Model
{
    protected $fillable = [
        'user_id', 'start_date', 'end_date', 'status', 'generation_inputs', 'version',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'generation_inputs' => 'array',
        ];
    }

    public function days(): HasMany
    {
        return $this->hasMany(MealPlanDay::class);
    }
}
