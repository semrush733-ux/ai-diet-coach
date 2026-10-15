<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoodSource extends Model
{
    protected $fillable = ['name', 'reference', 'retrieved_at', 'license_note'];

    protected function casts(): array
    {
        return ['retrieved_at' => 'date'];
    }
}
