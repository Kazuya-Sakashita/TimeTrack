"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { ArrowLeft, Loader2 } from "lucide-react";
import {
  type Attendance,
  createChangeRequest,
  fetchAttendances,
} from "@/lib/api";
import { tokenStore } from "@/lib/auth";
import { formatDate } from "@/lib/format";

// workDate(YYYY-MM-DD) + time(HH:MM) → ISO8601(+09:00)。time が空なら null。
function toIso(workDate: string, time: string): string | null {
  if (!time) return null;
  return `${workDate}T${time}:00+09:00`;
}

export default function NewRequestPage() {
  const router = useRouter();
  const [attendances, setAttendances] = useState<Attendance[]>([]);
  const [attendanceId, setAttendanceId] = useState("");
  const [clockIn, setClockIn] = useState("");
  const [clockOut, setClockOut] = useState("");
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const token = tokenStore.get();
    if (!token) {
      router.replace("/login");
      return;
    }
    fetchAttendances(token, 1, 50)
      .then((res) => {
        setAttendances(res.attendances);
        if (res.attendances[0]) setAttendanceId(res.attendances[0].id);
      })
      .catch(() => {
        tokenStore.clear();
        router.replace("/login");
      });
  }, [router]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const token = tokenStore.get();
    if (!token) return;
    const target = attendances.find((a) => a.id === attendanceId);
    if (!target) return;

    setSubmitting(true);
    setError(null);
    try {
      await createChangeRequest(token, {
        attendanceId,
        proposedClockInAt: toIso(target.workDate, clockIn),
        proposedClockOutAt: toIso(target.workDate, clockOut),
        reason,
      });
      router.push("/requests");
    } catch (err) {
      setError(err instanceof Error ? err.message : "申請に失敗しました");
      setSubmitting(false);
    }
  }

  return (
    <main className="mx-auto flex min-h-svh max-w-md flex-col gap-6 p-6">
      <header className="flex items-center gap-3">
        <Link
          href="/requests"
          className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
          戻る
        </Link>
        <h1 className="text-xl font-semibold">新規 修正申請</h1>
      </header>

      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <label htmlFor="attendance" className="text-sm font-medium">
            対象日
          </label>
          <select
            id="attendance"
            value={attendanceId}
            onChange={(e) => setAttendanceId(e.target.value)}
            required
            className="h-10 rounded-md border border-input bg-card px-3 text-sm"
          >
            {attendances.length === 0 && <option value="">勤怠がありません</option>}
            {attendances.map((a) => (
              <option key={a.id} value={a.id}>
                {formatDate(a.workDate)}
              </option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="flex flex-col gap-2">
            <label htmlFor="in" className="text-sm font-medium">
              修正後 出勤
            </label>
            <input
              id="in"
              type="time"
              value={clockIn}
              onChange={(e) => setClockIn(e.target.value)}
              className="h-10 rounded-md border border-input bg-card px-3 text-sm"
            />
          </div>
          <div className="flex flex-col gap-2">
            <label htmlFor="out" className="text-sm font-medium">
              修正後 退勤
            </label>
            <input
              id="out"
              type="time"
              value={clockOut}
              onChange={(e) => setClockOut(e.target.value)}
              className="h-10 rounded-md border border-input bg-card px-3 text-sm"
            />
          </div>
        </div>
        <p className="text-xs text-muted-foreground">
          出勤・退勤のうち修正したい時刻を入力してください（最低1つ）。
        </p>

        <div className="flex flex-col gap-2">
          <label htmlFor="reason" className="text-sm font-medium">
            理由
          </label>
          <textarea
            id="reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            required
            rows={3}
            className="rounded-md border border-input bg-card px-3 py-2 text-sm"
          />
        </div>

        {error && (
          <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={submitting || !attendanceId}
          className="flex h-10 items-center justify-center gap-2 rounded-md bg-primary text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-60"
        >
          {submitting && <Loader2 className="size-4 animate-spin" />}
          {submitting ? "送信中..." : "申請する"}
        </button>
      </form>
    </main>
  );
}
