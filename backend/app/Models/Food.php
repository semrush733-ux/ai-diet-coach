<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Food extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'slug', 'name', 'category', 'default_serving_size', 'serving_unit',
        'image_path', 'is_halal_suitable', 'is_vegetarian', 'is_vegan',
        'data_quality_status', 'last_verified_at',
    ];

    protected function casts(): array
    {
        return [
            'default_serving_size' => 'decimal:1',
            'is_halal_suitable' => 'boolean',
            'is_vegetarian' => 'boolean',
            'is_vegan' => 'boolean',
            'last_verified_at' => 'datetime',
        ];
    }

    public function nutrition(): HasOne
    {
        return $this->hasOne(FoodNutrition::class)->latest('version');
    }

    public function countries(): BelongsToMany
    {
        return $this->belongsToMany(Country::class, 'food_country_availability', 'food_id', 'country_id');
    }
}
