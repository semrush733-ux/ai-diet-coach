<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfile extends Model
{
    protected $fillable = [
        'user_id', 'display_name', 'date_of_birth', 'height_cm', 'weight_kg',
        'unit_system', 'country_code', 'region', 'timezone', 'locale',
        'avatar_path', 'goal_codes', 'dietary_preference_codes', 'allergy_codes',
    ];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'height_cm' => 'decimal:1',
            'weight_kg' => 'decimal:1',
            'goal_codes' => 'array',
            'dietary_preference_codes' => 'array',
            'allergy_codes' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
