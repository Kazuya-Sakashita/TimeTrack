// Walking Skeleton の確認ページ。
// Server Component から backend の /health を呼び、frontend → backend → db の
// 疎通を画面に表示する（Slice 0 の DoD）。
// - サーバー間通信: API_INTERNAL_URL（docker network 内の backend）
// - ブラウザ向け公開 URL: NEXT_PUBLIC_API_BASE_URL（今後のクライアント取得で使用）

type Health = { status: string; db: string };

async function fetchHealth(): Promise<Health | null> {
  const base = process.env.API_INTERNAL_URL ?? "http://backend:3000";
  try {
    const res = await fetch(`${base}/health`, { cache: "no-store" });
    if (!res.ok) return null;
    return (await res.json()) as Health;
  } catch {
    return null;
  }
}

export default async function Home() {
  const health = await fetchHealth();
  const ok = health?.status === "ok" && health?.db === "ok";
  const publicBase = process.env.NEXT_PUBLIC_API_BASE_URL ?? "(未設定)";

  return (
    <main className="mx-auto flex min-h-screen max-w-xl flex-col items-center justify-center gap-6 p-8">
      <h1 className="text-2xl font-semibold tracking-tight">TimeTrack</h1>
      <p className="text-sm text-zinc-500">Slice 0 — Walking Skeleton 疎通確認</p>

      <div className="w-full rounded-lg border p-5">
        <div className="flex items-center gap-2">
          <span
            className={`inline-block size-2.5 rounded-full ${
              ok ? "bg-green-500" : "bg-red-500"
            }`}
          />
          <span className="font-medium">
            {ok ? "Backend 疎通 OK" : "Backend 疎通 NG"}
          </span>
        </div>
        <dl className="mt-4 grid grid-cols-2 gap-2 font-mono text-sm">
          <dt className="text-zinc-500">status</dt>
          <dd>{health?.status ?? "-"}</dd>
          <dt className="text-zinc-500">db</dt>
          <dd>{health?.db ?? "-"}</dd>
        </dl>
      </div>

      <p className="font-mono text-xs text-zinc-400">
        NEXT_PUBLIC_API_BASE_URL = {publicBase}
      </p>
    </main>
  );
}
