<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GlucoseReading extends Model
{
    protected $fillable = [
        'user_id', 'value_original', 'unit_original', 'value_mg_dl',
        'context', 'measured_at', 'minutes_since_meal', 'note', 'source',
    ];

    protected function casts(): array
    {
        return [
            'measured_at' => 'datetime',
            'value_original' => 'decimal:2',
            'value_mg_dl' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
