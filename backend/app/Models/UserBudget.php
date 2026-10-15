<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserBudget extends Model
{
    protected $fillable = ['user_id', 'budget_tier', 'weekly_amount', 'currency_code'];

    protected function casts(): array
    {
        return ['weekly_amount' => 'decimal:2'];
    }
}
