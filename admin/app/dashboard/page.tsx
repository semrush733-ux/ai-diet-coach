import { apiGet } from "@/lib/api";

interface OverviewStats {
  total_users: number;
  onboarded_users: number;
  foods: number;
  glucose_readings: number;
}

/**
 * Dashboard overview. Shows REAL backend counts only — when the stats
 * endpoint (Phase 2) or the backend itself is unavailable, it says so
 * explicitly instead of rendering fabricated metrics.
 */
export default async function DashboardPage() {
  const { data, error } = await apiGet<OverviewStats>(
    "/admin/stats/overview"
  );

  const cards: { label: string; value: number | null }[] = [
    { label: "Total users", value: data?.total_users ?? null },
    { label: "Onboarded users", value: data?.onboarded_users ?? null },
    { label: "Foods in database", value: data?.foods ?? null },
    { label: "Glucose readings", value: data?.glucose_readings ?? null },
  ];

  return (
    <main className="mx-auto max-w-6xl p-6">
      <header className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Overview</h1>
          <p className="text-sm text-muted">AI Diet Coach administration</p>
        </div>
        <span className="rounded-full bg-brand/10 px-3 py-1 text-sm font-medium text-brand">
          Phase 1 shell
        </span>
      </header>

      {error && (
        <div className="mb-6 rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-900">
          <strong>Live data unavailable:</strong> {error.message}{" "}
          {error.code === "not_found" || error.code === "http_error"
            ? "The admin stats endpoint ships in Phase 2."
            : "Start the backend (php artisan serve) and reload."}
        </div>
      )}

      <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((card) => (
          <div
            key={card.label}
            className="rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-200"
          >
            <p className="text-sm text-muted">{card.label}</p>
            <p className="mt-2 text-3xl font-bold">
              {card.value === null ? (
                <span className="text-slate-300">—</span>
              ) : (
                card.value.toLocaleString()
              )}
            </p>
          </div>
        ))}
      </section>

      <section className="mt-8 rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-200">
        <h2 className="font-semibold">Coming in later phases</h2>
        <ul className="mt-3 grid list-disc grid-cols-1 gap-x-8 gap-y-1 pl-5 text-sm text-muted sm:grid-cols-2">
          <li>User management (role-based, health data gated + audited)</li>
          <li>Food &amp; nutrition data management with review workflow</li>
          <li>Meal plan template approval &amp; versioning</li>
          <li>Seasonal food calendars</li>
          <li>AI provider configuration &amp; usage monitoring</li>
          <li>Subscriptions &amp; support tickets</li>
        </ul>
      </section>
    </main>
  );
}
