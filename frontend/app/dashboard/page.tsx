"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Clock3, LogOut } from "lucide-react";
import { type ApiUser, fetchMe, logout } from "@/lib/api";
import { tokenStore } from "@/lib/auth";

const roleLabel: Record<ApiUser["role"], string> = {
  employee: "従業員",
  manager: "マネージャー",
  admin: "管理者",
};

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<ApiUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = tokenStore.get();
    if (!token) {
      router.replace("/login");
      return;
    }
    fetchMe(token)
      .then(setUser)
      .catch(() => {
        tokenStore.clear();
        router.replace("/login");
      })
      .finally(() => setLoading(false));
  }, [router]);

  async function handleLogout() {
    const token = tokenStore.get();
    if (token) await logout(token);
    tokenStore.clear();
    router.replace("/login");
  }

  if (loading) {
    return (
      <main className="flex min-h-svh items-center justify-center text-sm text-muted-foreground">
        読み込み中...
      </main>
    );
  }

  if (!user) return null;

  return (
    <main className="mx-auto flex min-h-svh max-w-2xl flex-col gap-6 p-6">
      <header className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="flex aspect-square size-9 items-center justify-center rounded-lg bg-primary text-primary-foreground">
            <Clock3 className="size-5" />
          </div>
          <span className="text-lg font-semibold">TimeTrack</span>
        </div>
        <button
          onClick={handleLogout}
          className="flex items-center gap-1.5 rounded-md border border-input px-3 py-1.5 text-sm hover:bg-accent"
        >
          <LogOut className="size-4" />
          ログアウト
        </button>
      </header>

      <div className="rounded-lg border bg-card p-6">
        <h1 className="text-xl font-semibold">ようこそ、{user.name} さん</h1>
        <dl className="mt-4 grid grid-cols-[6rem_1fr] gap-2 text-sm">
          <dt className="text-muted-foreground">ID</dt>
          <dd className="font-mono">{user.id}</dd>
          <dt className="text-muted-foreground">メール</dt>
          <dd>{user.email}</dd>
          <dt className="text-muted-foreground">ロール</dt>
          <dd>{roleLabel[user.role]}</dd>
        </dl>
      </div>

      <p className="text-sm text-muted-foreground">
        Slice 1（認証）完了。次は打刻機能（Slice 2）を実装します。
      </p>
    </main>
  );
}
