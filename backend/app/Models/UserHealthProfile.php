<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Sensitive health data — access only via user-scoped policies.
 * Admin access requires explicit `health.read` permission + audit log.
 */
class UserHealthProfile extends Model
{
    protected $fillable = [
        'user_id', 'diabetes_status', 'glucose_unit',
        'clinician_target_low_mg_dl', 'clinician_target_high_mg_dl',
        'medication_categories', 'requires_clinician_flag', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'medication_categories' => 'array',
            'requires_clinician_flag' => 'boolean',
            'clinician_target_low_mg_dl' => 'decimal:1',
            'clinician_target_high_mg_dl' => 'decimal:1',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
