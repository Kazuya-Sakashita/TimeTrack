"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { ArrowLeft, Plus } from "lucide-react";
import { type AttendanceChangeRequest, fetchChangeRequests } from "@/lib/api";
import { tokenStore } from "@/lib/auth";
import { RequestStatusBadge } from "@/components/status-badge";
import { formatTime } from "@/lib/format";

export default function RequestsPage() {
  const router = useRouter();
  const [requests, setRequests] = useState<AttendanceChangeRequest[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = tokenStore.get();
    if (!token) {
      router.replace("/login");
      return;
    }
    fetchChangeRequests(token)
      .then(setRequests)
      .catch(() => {
        tokenStore.clear();
        router.replace("/login");
      })
      .finally(() => setLoading(false));
  }, [router]);

  return (
    <main className="mx-auto flex min-h-svh max-w-2xl flex-col gap-6 p-6">
      <header className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard"
            className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="size-4" />
            ダッシュボード
          </Link>
          <h1 className="text-xl font-semibold">修正申請</h1>
        </div>
        <Link
          href="/requests/new"
          className="flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:bg-primary/90"
        >
          <Plus className="size-4" />
          新規申請
        </Link>
      </header>

      {loading ? (
        <p className="text-sm text-muted-foreground">読み込み中...</p>
      ) : requests.length === 0 ? (
        <p className="rounded-lg border bg-card p-8 text-center text-sm text-muted-foreground">
          申請はまだありません
        </p>
      ) : (
        <ul className="flex flex-col gap-3">
          {requests.map((r) => (
            <li key={r.id} className="rounded-lg border bg-card p-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">
                  申請日 {new Date(r.createdAt).toLocaleDateString("ja-JP")}
                </span>
                <RequestStatusBadge status={r.status} />
              </div>
              <dl className="mt-3 grid grid-cols-[7rem_1fr] gap-1.5 text-sm">
                <dt className="text-muted-foreground">修正後 出勤</dt>
                <dd className="font-mono">{formatTime(r.proposedClockInAt)}</dd>
                <dt className="text-muted-foreground">修正後 退勤</dt>
                <dd className="font-mono">{formatTime(r.proposedClockOutAt)}</dd>
                <dt className="text-muted-foreground">理由</dt>
                <dd>{r.reason}</dd>
                {r.reviewComment && (
                  <>
                    <dt className="text-muted-foreground">承認者コメント</dt>
                    <dd>{r.reviewComment}</dd>
                  </>
                )}
              </dl>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
