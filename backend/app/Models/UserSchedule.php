<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserSchedule extends Model
{
    protected $fillable = [
        'user_id', 'wake_time', 'breakfast_time', 'lunch_time',
        'dinner_time', 'bed_time', 'wants_snacks',
    ];

    protected function casts(): array
    {
        return ['wants_snacks' => 'boolean'];
    }
}
