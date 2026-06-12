"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { ArrowLeft } from "lucide-react";
import { type MonthlyReport, fetchMonthlyReport } from "@/lib/api";
import { tokenStore } from "@/lib/auth";
import { formatMinutes } from "@/lib/format";
import { AttendanceStatusBadge } from "@/components/status-badge";

function currentMonth(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border bg-card p-4">
      <p className="text-sm text-muted-foreground">{label}</p>
      <p className="mt-1 text-2xl font-semibold tabular-nums tracking-tight">{value}</p>
    </div>
  );
}

export default function ReportsPage() {
  const router = useRouter();
  const [month, setMonth] = useState(currentMonth());
  const [report, setReport] = useState<MonthlyReport | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(
    (m: string) => {
      const token = tokenStore.get();
      if (!token) {
        router.replace("/login");
        return;
      }
      fetchMonthlyReport(token, m)
        .then(setReport)
        .catch(() => {
          tokenStore.clear();
          router.replace("/login");
        })
        .finally(() => setLoading(false));
    },
    [router],
  );

  useEffect(() => {
    load(month);
  }, [load, month]);

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
          <h1 className="text-xl font-semibold">月次サマリー</h1>
        </div>
        <input
          type="month"
          value={month}
          onChange={(e) => setMonth(e.target.value)}
          className="h-9 rounded-md border border-input bg-card px-3 text-sm"
        />
      </header>

      {loading || !report ? (
        <p className="text-sm text-muted-foreground">読み込み中...</p>
      ) : (
        <>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <Stat label="勤務日数" value={`${report.workingDays}日`} />
            <Stat label="総勤務" value={formatMinutes(report.totalWorkMinutes)} />
            <Stat label="残業" value={formatMinutes(report.overtimeMinutes)} />
            <Stat label="総休憩" value={formatMinutes(report.totalBreakMinutes)} />
          </div>

          <div className="overflow-hidden rounded-lg border bg-card">
            <table className="w-full text-sm">
              <thead className="border-b bg-muted/50 text-left text-muted-foreground">
                <tr>
                  <th className="px-4 py-3 font-medium">日付</th>
                  <th className="px-4 py-3 font-medium">勤務</th>
                  <th className="px-4 py-3 font-medium">休憩</th>
                  <th className="px-4 py-3 font-medium">残業</th>
                  <th className="px-4 py-3 font-medium">状態</th>
                </tr>
              </thead>
              <tbody>
                {report.days.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                      この月の勤怠はありません
                    </td>
                  </tr>
                ) : (
                  report.days.map((d) => (
                    <tr key={d.date} className="border-b last:border-0">
                      <td className="px-4 py-3">{d.date}</td>
                      <td className="px-4 py-3 font-mono tabular-nums">
                        {formatMinutes(d.workMinutes)}
                      </td>
                      <td className="px-4 py-3 font-mono tabular-nums">
                        {formatMinutes(d.breakMinutes)}
                      </td>
                      <td className="px-4 py-3 font-mono tabular-nums">
                        {d.overtimeMinutes > 0 ? formatMinutes(d.overtimeMinutes) : "—"}
                      </td>
                      <td className="px-4 py-3">
                        <AttendanceStatusBadge status={d.status} />
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </>
      )}
    </main>
  );
}
