<?php

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Controller;

/**
 * Base controller enforcing the consistent JSON envelope.
 */
abstract class ApiController extends Controller
{
    protected function success(mixed $data = null, array $meta = [], int $status = 200): JsonResponse
    {
        $payload = ['data' => $data];
        if ($meta !== []) {
            $payload['meta'] = $meta;
        }

        return response()->json($payload, $status);
    }

    protected function failure(string $code, string $message, int $status, array $details = []): JsonResponse
    {
        return response()->json([
            'error' => [
                'code' => $code,
                'message' => $message,
                'details' => (object) $details,
            ],
        ], $status);
    }

    /**
     * Honest 501 for contracted-but-not-yet-built features (never fake data).
     */
    protected function notImplemented(string $message): JsonResponse
    {
        return $this->failure('not_implemented', $message, 501);
    }
}
