"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { ArrowLeft } from "lucide-react";
import { type AttendanceList, fetchAttendances } from "@/lib/api";
import { tokenStore } from "@/lib/auth";
import { AttendanceStatusBadge } from "@/components/status-badge";
import { formatDate, formatMinutes, formatTime } from "@/lib/format";

const PER_PAGE = 20;

export default function HistoryPage() {
  const router = useRouter();
  const [data, setData] = useState<AttendanceList | null>(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  const load = useCallback(
    (p: number) => {
      const token = tokenStore.get();
      if (!token) {
        router.replace("/login");
        return;
      }
      fetchAttendances(token, p, PER_PAGE)
        .then(setData)
        .catch(() => {
          tokenStore.clear();
          router.replace("/login");
        })
        .finally(() => setLoading(false));
    },
    [router],
  );

  useEffect(() => {
    load(page);
  }, [load, page]);

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
        <h1 className="text-xl font-semibold">勤怠履歴</h1>
      </header>

      <div className="overflow-hidden rounded-lg border bg-card">
        <table className="w-full text-sm">
          <thead className="border-b bg-muted/50 text-left text-muted-foreground">
            <tr>
              <th className="px-4 py-3 font-medium">日付</th>
              <th className="px-4 py-3 font-medium">出勤</th>
              <th className="px-4 py-3 font-medium">退勤</th>
              <th className="px-4 py-3 font-medium">勤務</th>
              <th className="px-4 py-3 font-medium">状態</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                  読み込み中...
                </td>
              </tr>
            ) : data && data.attendances.length > 0 ? (
              data.attendances.map((a) => (
                <tr key={a.id} className="border-b last:border-0">
                  <td className="px-4 py-3">{formatDate(a.workDate)}</td>
                  <td className="px-4 py-3 font-mono tabular-nums">
                    {formatTime(a.clockInAt)}
                  </td>
                  <td className="px-4 py-3 font-mono tabular-nums">
                    {formatTime(a.clockOutAt)}
                  </td>
                  <td className="px-4 py-3 font-mono tabular-nums">
                    {formatMinutes(a.workMinutes)}
                  </td>
                  <td className="px-4 py-3">
                    <AttendanceStatusBadge status={a.status} />
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                  勤怠記録がありません
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {data && data.pagination.totalPages > 1 && (
        <div className="flex items-center justify-center gap-4 text-sm">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page <= 1}
            className="rounded-md border border-input px-3 py-1.5 disabled:opacity-50"
          >
            前へ
          </button>
          <span className="text-muted-foreground">
            {data.pagination.page} / {data.pagination.totalPages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(data.pagination.totalPages, p + 1))}
            disabled={page >= data.pagination.totalPages}
            className="rounded-md border border-input px-3 py-1.5 disabled:opacity-50"
          >
            次へ
          </button>
        </div>
      )}
    </main>
  );
}
