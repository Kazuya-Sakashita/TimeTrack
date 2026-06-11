"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Clock3, LogIn, LogOut } from "lucide-react";
import {
  type ApiUser,
  type Attendance,
  clockIn,
  clockOut,
  fetchMe,
  logout,
} from "@/lib/api";
import { tokenStore } from "@/lib/auth";

function formatTime(iso: string | null): string {
  if (!iso) return "--:--";
  return new Date(iso).toLocaleTimeString("ja-JP", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatMinutes(min: number | null): string {
  if (min == null) return "--";
  return `${Math.floor(min / 60)}時間${min % 60}分`;
}

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

  async function handleClockIn() {
    const token = tokenStore.get();
    if (!token) return;
    setClocking(true);
    setClockError(null);
    try {
      setAttendance(await clockIn(token));
    } catch (err) {
      setClockError(err instanceof Error ? err.message : "出勤打刻に失敗しました");
    } finally {
      setClocking(false);
    }
  }

  async function handleClockOut() {
    const token = tokenStore.get();
    if (!token) return;
    setClocking(true);
    setClockError(null);
    try {
      setAttendance(await clockOut(token));
    } catch (err) {
      setClockError(err instanceof Error ? err.message : "退勤打刻に失敗しました");
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

      {/* 打刻（clock-widget の出勤・退勤部分。休憩は後続スライス） */}
      <div className="rounded-lg border bg-card p-6">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm text-muted-foreground">本日の勤怠</p>
            <p className="mt-1 flex items-center gap-2">
              <span
                className={`inline-block size-2 rounded-full ${
                  attendance?.status === "working"
                    ? "bg-success"
                    : "bg-muted-foreground/40"
                }`}
              />
              <span className="font-medium">
                {attendance?.status === "working" &&
                  `勤務中 · ${formatTime(attendance.clockInAt)} 出勤`}
                {attendance?.status === "finished" &&
                  `退勤済 · 勤務 ${formatMinutes(attendance.workMinutes)}`}
                {!attendance && "未出勤"}
              </span>
            </p>
          </div>

          {attendance?.status === "working" ? (
            <button
              onClick={handleClockOut}
              disabled={clocking}
              className="flex h-12 items-center gap-2 rounded-md bg-destructive px-5 text-sm font-medium text-destructive-foreground transition-colors hover:bg-destructive/90 disabled:opacity-60"
            >
              <LogOut className="size-4" />
              {clocking ? "打刻中..." : "退勤"}
            </button>
          ) : (
            <button
              onClick={handleClockIn}
              disabled={clocking || attendance?.status === "finished"}
              className="flex h-12 items-center gap-2 rounded-md bg-primary px-5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
            >
              <LogIn className="size-4" />
              {clocking ? "打刻中..." : "出勤"}
            </button>
          )}
        </div>
        {clockError && (
          <p className="mt-3 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {clockError}
          </p>
        )}
      </div>
    </main>
  );
}
