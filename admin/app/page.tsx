import Link from "next/link";

/**
 * Admin sign-in shell. The admin auth endpoint ships in Phase 2;
 * the form posts nowhere yet and says so honestly.
 */
export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center p-6">
      <div className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-sm ring-1 ring-slate-200">
        <div className="mb-6 flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-brand text-lg font-bold text-white">
            A
          </div>
          <div>
            <h1 className="text-lg font-semibold">AI Diet Coach</h1>
            <p className="text-sm text-muted">Admin Dashboard</p>
          </div>
        </div>

        <form className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              className="w-full rounded-xl border border-slate-300 px-4 py-2.5 outline-none focus:border-brand focus:ring-1 focus:ring-brand"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium" htmlFor="password">
              Password
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              className="w-full rounded-xl border border-slate-300 px-4 py-2.5 outline-none focus:border-brand focus:ring-1 focus:ring-brand"
            />
          </div>
          <button
            type="button"
            disabled
            title="Admin authentication ships in Phase 2"
            className="w-full cursor-not-allowed rounded-xl bg-brand/60 py-2.5 font-semibold text-white"
          >
            Sign in
          </button>
          <p className="text-center text-xs text-muted">
            Admin authentication is implemented in Phase 2. Preview the
            dashboard shell{" "}
            <Link href="/dashboard" className="font-medium text-brand underline">
              here
            </Link>
            .
          </p>
        </form>
      </div>
    </main>
  );
}
