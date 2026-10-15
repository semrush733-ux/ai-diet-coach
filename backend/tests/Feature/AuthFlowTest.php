<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class AuthFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_login_and_profile(): void
    {
        Notification::fake();

        $register = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'device_name' => 'tests',
        ]);

        $register->assertCreated()->assertJsonStructure([
            'data' => ['token', 'user' => ['id', 'email', 'display_name', 'onboarded']],
        ]);

        $token = $register->json('data.token');

        $this->withToken($token)
            ->getJson('/api/v1/profile')
            ->assertOk()
            ->assertJsonPath('data.email', 'test@example.com')
            ->assertJsonPath('data.onboarded', false);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'test@example.com',
            'password' => 'wrong-password',
            'device_name' => 'tests',
        ])->assertStatus(401)->assertJsonPath('error.code', 'invalid_credentials');
    }
}
