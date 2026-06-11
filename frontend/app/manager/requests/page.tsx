"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { ArrowLeft } from "lucide-react";
import {
  type AttendanceChangeRequest,
  fetchChangeRequests,
  fetchMe,
  reviewChangeRequest,
} from "@/lib/api";
import { tokenStore } from "@/lib/auth";
import { RequestStatusBadge } from "@/components/status-badge";
import { formatTime } from "@/lib/format";

export default function ManagerRequestsPage() {
  const router = useRouter();
  const [requests, setRequests] = useState<AttendanceChangeRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [comments, setComments] = useState<Record<string, string>>({});
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [onlyPending, setOnlyPending] = useState(true);

  const load = useCallback(() => {
    const token = tokenStore.get();
    if (!token) {
      router.replace("/login");
      return;
    }
    fetchChangeRequests(token, onlyPending ? "pending" : undefined)
      .then(setRequests)
      .catch(() => {
        tokenStore.clear();
        router.replace("/login");
      })
      .finally(() => setLoading(false));
  }, [router, onlyPending]);

  useEffect(() => {
    // 承認権限の確認（manager/admin 以外はダッシュボードへ）
    const token = tokenStore.get();
    if (!token) {
      router.replace("/login");
      return;
    }
    fetchMe(token)
      .then((u) => {
        if (u.role === "employee") {
          router.replace("/dashboard");
          return;
        }
        load();
      })
      .catch(() => {
        tokenStore.clear();
        router.replace("/login");
      });
  }, [router, load]);

  async function review(id: string, status: "approved" | "rejected") {
    const token = tokenStore.get();
    if (!token) return;
    setBusyId(id);
    setError(null);
    try {
      await reviewChangeRequest(token, id, status, comments[id]);
      load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "処理に失敗しました");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <main className="mx-auto flex min-h-svh max-w-2xl flex-col gap-6 p-6">
      <header className="flex items-center gap-3">
        <Link
          href="/dashboard"
          className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
          ダッシュボード
        </Link>
        <h1 className="text-xl font-semibold">修正申請の承認</h1>
      </header>

      <div className="flex gap-2 text-sm">
        <button
          onClick={() => setOnlyPending(true)}
          className={`rounded-md px-3 py-1.5 ${onlyPending ? "bg-primary text-primary-foreground" : "border border-input hover:bg-accent"}`}
        >
          申請中のみ
        </button>
        <button
          onClick={() => setOnlyPending(false)}
          className={`rounded-md px-3 py-1.5 ${!onlyPending ? "bg-primary text-primary-foreground" : "border border-input hover:bg-accent"}`}
        >
          すべて
        </button>
      </div>

      {error && (
        <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      )}

      {loading ? (
        <p className="text-sm text-muted-foreground">読み込み中...</p>
      ) : requests.length === 0 ? (
        <p className="rounded-lg border bg-card p-8 text-center text-sm text-muted-foreground">
          申請はありません
        </p>
      ) : (
        <ul className="flex flex-col gap-3">
          {requests.map((r) => (
            <li key={r.id} className="rounded-lg border bg-card p-4">
              <div className="flex items-center justify-between">
                <span className="font-medium">{r.applicantName}</span>
                <RequestStatusBadge status={r.status} />
              </div>
              <dl className="mt-3 grid grid-cols-[7rem_1fr] gap-1.5 text-sm">
                <dt className="text-muted-foreground">修正後 出勤</dt>
                <dd className="font-mono">{formatTime(r.proposedClockInAt)}</dd>
                <dt className="text-muted-foreground">修正後 退勤</dt>
                <dd className="font-mono">{formatTime(r.proposedClockOutAt)}</dd>
                <dt className="text-muted-foreground">理由</dt>
                <dd>{r.reason}</dd>
              </dl>

              {r.status === "pending" && (
                <div className="mt-4 flex flex-col gap-2">
                  <input
                    type="text"
                    placeholder="コメント（任意）"
                    value={comments[r.id] ?? ""}
                    onChange={(e) =>
                      setComments((c) => ({ ...c, [r.id]: e.target.value }))
                    }
                    className="h-9 rounded-md border border-input bg-card px-3 text-sm"
                  />
                  <div className="flex gap-2">
                    <button
                      onClick={() => review(r.id, "approved")}
                      disabled={busyId === r.id}
                      className="flex-1 rounded-md bg-success px-3 py-2 text-sm font-medium text-success-foreground hover:bg-success/90 disabled:opacity-60"
                    >
                      承認
                    </button>
                    <button
                      onClick={() => review(r.id, "rejected")}
                      disabled={busyId === r.id}
                      className="flex-1 rounded-md bg-destructive px-3 py-2 text-sm font-medium text-destructive-foreground hover:bg-destructive/90 disabled:opacity-60"
                    >
                      却下
                    </button>
                  </div>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
