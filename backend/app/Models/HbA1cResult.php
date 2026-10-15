<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HbA1cResult extends Model
{
    protected $table = 'hba1c_results';

    protected $fillable = ['user_id', 'value_percent', 'tested_at', 'lab_name', 'note'];

    protected function casts(): array
    {
        return ['tested_at' => 'date', 'value_percent' => 'decimal:1'];
    }
}
