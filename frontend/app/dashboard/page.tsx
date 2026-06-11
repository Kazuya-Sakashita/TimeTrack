"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import Link from "next/link";
import {
  CalendarClock,
  ClipboardCheck,
  Clock3,
  Coffee,
  FileText,
  LogIn,
  LogOut,
  Play,
} from "lucide-react";
import {
  type ApiUser,
  type Attendance,
  breakEnd,
  breakStart,
  clockIn,
  clockOut,
  fetchMe,
  logout,
} from "@/lib/api";
import { tokenStore } from "@/lib/auth";
import { formatMinutes, formatTime } from "@/lib/format";

const roleLabel: Record<ApiUser["role"], string> = {
  employee: "従業員",
  manager: "マネージャー",
  admin: "管理者",
};

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<ApiUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [attendance, setAttendance] = useState<Attendance | null>(null);
  const [clocking, setClocking] = useState(false);
  const [clockError, setClockError] = useState<string | null>(null);

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

  async function runAction(action: (token: string) => Promise<Attendance>) {
    const token = tokenStore.get();
    if (!token) return;
    setClocking(true);
    setClockError(null);
    try {
      setAttendance(await action(token));
    } catch (err) {
      setClockError(err instanceof Error ? err.message : "打刻に失敗しました");
    } finally {
      setClocking(false);
    }
  }

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

      {/* 打刻（clock-widget: 出勤・退勤・休憩） */}
      <div className="rounded-lg border bg-card p-6">
        <div>
          <p className="text-sm text-muted-foreground">本日の勤怠</p>
          <p className="mt-1 flex items-center gap-2">
            <span
              className={`inline-block size-2 rounded-full ${
                attendance?.status === "working"
                  ? "bg-success animate-pulse"
                  : attendance?.status === "on_break"
                    ? "bg-warning animate-pulse"
                    : "bg-muted-foreground/40"
              }`}
            />
            <span className="font-medium">
              {attendance?.status === "working" &&
                `勤務中 · ${formatTime(attendance.clockInAt)} 出勤`}
              {attendance?.status === "on_break" && "休憩中"}
              {attendance?.status === "finished" &&
                `退勤済 · 勤務 ${formatMinutes(attendance.workMinutes)}`}
              {!attendance && "未出勤"}
            </span>
          </p>
        </div>

        <div className="mt-4 grid grid-cols-2 gap-3">
          {!attendance && (
            <button
              onClick={() => runAction(clockIn)}
              disabled={clocking}
              className="col-span-2 flex h-12 items-center justify-center gap-2 rounded-md bg-primary text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-60"
            >
              <LogIn className="size-4" />
              出勤
            </button>
          )}

          {attendance?.status === "working" && (
            <>
              <button
                onClick={() => runAction((t) => clockOut(t, attendance.id))}
                disabled={clocking}
                className="flex h-12 items-center justify-center gap-2 rounded-md bg-destructive text-sm font-medium text-destructive-foreground hover:bg-destructive/90 disabled:opacity-60"
              >
                <LogOut className="size-4" />
                退勤
              </button>
              <button
                onClick={() => runAction((t) => breakStart(t, attendance.id))}
                disabled={clocking}
                className="flex h-12 items-center justify-center gap-2 rounded-md border border-input text-sm font-medium hover:bg-accent disabled:opacity-60"
              >
                <Coffee className="size-4" />
                休憩開始
              </button>
            </>
          )}

          {attendance?.status === "on_break" && (
            <button
              onClick={() =>
                attendance.openBreakId &&
                runAction((t) => breakEnd(t, attendance.id, attendance.openBreakId!))
              }
              disabled={clocking}
              className="col-span-2 flex h-12 items-center justify-center gap-2 rounded-md bg-primary text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-60"
            >
              <Play className="size-4" />
              休憩終了
            </button>
          )}

          {attendance?.status === "finished" && (
            <p className="col-span-2 text-center text-sm text-muted-foreground">
              本日は退勤済みです（休憩 {formatMinutes(attendance.breakMinutes)}）
            </p>
          )}
        </div>

        {clockError && (
          <p className="mt-3 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {clockError}
          </p>
        )}
      </div>

      <div className="grid grid-cols-2 gap-3">
        <Link
          href="/history"
          className="flex items-center gap-2 rounded-lg border bg-card p-4 text-sm font-medium hover:bg-accent"
        >
          <CalendarClock className="size-4 text-muted-foreground" />
          勤怠履歴
        </Link>
        <Link
          href="/requests"
          className="flex items-center gap-2 rounded-lg border bg-card p-4 text-sm font-medium hover:bg-accent"
        >
          <FileText className="size-4 text-muted-foreground" />
          修正申請
        </Link>
        {user.role !== "employee" && (
          <Link
            href="/manager/requests"
            className="col-span-2 flex items-center gap-2 rounded-lg border bg-card p-4 text-sm font-medium hover:bg-accent"
          >
            <ClipboardCheck className="size-4 text-muted-foreground" />
            修正申請の承認（管理者）
          </Link>
        )}
      </div>
    </main>
  );
}
