<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Country extends Model
{
    protected $fillable = ['iso2', 'name', 'hemisphere', 'default_currency'];
}
