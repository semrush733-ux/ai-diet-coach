<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = ['email', 'password', 'status', 'google_id', 'apple_id'];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'onboarded_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class);
    }

    public function healthProfile(): HasOne
    {
        return $this->hasOne(UserHealthProfile::class);
    }

    public function schedule(): HasOne
    {
        return $this->hasOne(UserSchedule::class);
    }

    public function budget(): HasOne
    {
        return $this->hasOne(UserBudget::class);
    }

    public function glucoseReadings(): HasMany
    {
        return $this->hasMany(GlucoseReading::class);
    }

    public function hba1cResults(): HasMany
    {
        return $this->hasMany(HbA1cResult::class);
    }

    public function mealPlans(): HasMany
    {
        return $this->hasMany(MealPlan::class);
    }
}
