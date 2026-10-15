export const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api/v1";

export interface ApiError {
  code: string;
  message: string;
}

/**
 * Thin fetch wrapper for the backend envelope { data } | { error }.
 * Admin auth endpoints land in Phase 2; this client is ready for them.
 */
export async function apiGet<T>(
  path: string,
  token?: string
): Promise<{ data?: T; error?: ApiError }> {
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      headers: {
        Accept: "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      cache: "no-store",
    });
    const body = await res.json();
    if (!res.ok) {
      return {
        error: body?.error ?? { code: "http_error", message: `HTTP ${res.status}` },
      };
    }
    return { data: body.data as T };
  } catch {
    return {
      error: { code: "network", message: "Backend is not reachable." },
    };
  }
}
