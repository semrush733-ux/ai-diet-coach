<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\Rules\Password as PasswordRule;

class AuthController extends ApiController
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
            'device_name' => ['required', 'string', 'max:80'],
            'locale' => ['sometimes', 'string', 'max:10'],
            'timezone' => ['sometimes', 'string', 'max:64'],
        ]);

        $user = DB::transaction(function () use ($validated) {
            $user = User::create([
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'status' => 'active',
            ]);

            UserProfile::create([
                'user_id' => $user->id,
                'display_name' => $validated['name'],
                'locale' => $validated['locale'] ?? 'en',
                'timezone' => $validated['timezone'] ?? 'UTC',
                'unit_system' => 'metric',
            ]);

            return $user;
        });

        $user->sendEmailVerificationNotification();

        $token = $user->createToken($validated['device_name'])->plainTextToken;

        return $this->success([
            'token' => $token,
            'user' => $this->userPayload($user),
        ], status: 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['required', 'string', 'max:80'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if ($user === null || ! Hash::check($validated['password'], (string) $user->password)) {
            return $this->failure('invalid_credentials', 'Email or password is incorrect.', 401);
        }

        if ($user->status === 'suspended') {
            return $this->failure('account_suspended', 'This account is suspended.', 403);
        }

        $token = $user->createToken($validated['device_name'])->plainTextToken;

        return $this->success([
            'token' => $token,
            'user' => $this->userPayload($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->success(null, status: 200);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $validated = $request->validate(['email' => ['required', 'email']]);

        // Fire-and-forget; identical response whether or not the account
        // exists, to prevent account enumeration.
        Password::sendResetLink(['email' => $validated['email']]);

        return $this->success([
            'message' => 'If an account exists for that email, a reset link has been sent.',
        ]);
    }

    private function userPayload(User $user): array
    {
        $profile = $user->profile;

        return [
            'id' => $user->id,
            'email' => $user->email,
            'display_name' => $profile?->display_name ?? '',
            'email_verified' => $user->hasVerifiedEmail(),
            'onboarded' => $user->onboarded_at !== null,
        ];
    }
}
