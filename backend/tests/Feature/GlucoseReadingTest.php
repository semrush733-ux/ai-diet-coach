<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class GlucoseReadingTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): User
    {
        $user = User::create([
            'email' => 'glucose@example.com',
            'password' => Hash::make('password123'),
            'status' => 'active',
        ]);
        UserProfile::create(['user_id' => $user->id, 'display_name' => 'G']);

        return $user;
    }

    public function test_store_converts_mmol_l_to_canonical_mg_dl(): void
    {
        $user = $this->actingUser();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/glucose-readings', [
            'value' => 7.2,
            'unit' => 'mmol_l',
            'context' => 'fasting',
            'measured_at' => now()->toIso8601String(),
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.unit_original', 'mmol_l')
            ->assertJsonPath('data.value_original', 7.2);

        // 7.2 × 18.016 = 129.7152 → 129.7 canonical
        $this->assertEqualsWithDelta(129.7, $response->json('data.value_mg_dl'), 0.01);
    }

    public function test_implausible_value_for_unit_is_rejected(): void
    {
        $user = $this->actingUser();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/glucose-readings', [
            'value' => 180, // plausible in mg/dL, impossible in mmol/L
            'unit' => 'mmol_l',
            'context' => 'random',
            'measured_at' => now()->toIso8601String(),
        ])->assertStatus(422)->assertJsonPath('error.code', 'validation_error');
    }

    public function test_users_cannot_touch_others_readings(): void
    {
        $owner = $this->actingUser();
        $reading = $owner->glucoseReadings()->create([
            'value_original' => 100, 'unit_original' => 'mg_dl', 'value_mg_dl' => 100,
            'context' => 'random', 'measured_at' => now(), 'source' => 'manual',
        ]);

        $other = User::create([
            'email' => 'other@example.com',
            'password' => Hash::make('password123'),
            'status' => 'active',
        ]);

        $this->actingAs($other, 'sanctum')
            ->deleteJson("/api/v1/glucose-readings/{$reading->id}")
            ->assertStatus(404);
    }
}
