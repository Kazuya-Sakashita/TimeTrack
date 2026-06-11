"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Clock3, Eye, EyeOff, Loader2 } from "lucide-react";
import { login } from "@/lib/api";
import { tokenStore } from "@/lib/auth";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("admin@example.com");
  const [password, setPassword] = useState("password");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const { token } = await login(email, password);
      tokenStore.set(token);
      router.push("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "ログインに失敗しました");
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-svh lg:grid-cols-2">
      {/* ブランドパネル（V0 デザイン基準） */}
      <div className="hidden flex-col justify-between bg-primary p-10 text-primary-foreground lg:flex">
        <div className="flex items-center gap-2">
          <div className="flex aspect-square size-9 items-center justify-center rounded-lg bg-primary-foreground/15">
            <Clock3 className="size-5" />
          </div>
          <span className="text-lg font-semibold">TimeTrack</span>
        </div>
        <div className="space-y-3">
          <h2 className="text-2xl font-semibold leading-snug">
            シンプルでモダンな
            <br />
            勤怠管理
          </h2>
          <p className="text-sm text-primary-foreground/80">
            出退勤・休憩・申請をひとつに。
          </p>
        </div>
        <p className="text-xs text-primary-foreground/60">© TimeTrack</p>
      </div>

      {/* フォーム */}
      <div className="flex flex-col items-center justify-center px-6 py-12">
        <div className="w-full max-w-sm">
          <div className="mb-8 flex flex-col gap-2">
            <div className="flex items-center gap-2 lg:hidden">
              <div className="flex aspect-square size-9 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                <Clock3 className="size-5" />
              </div>
              <span className="text-lg font-semibold">TimeTrack</span>
            </div>
            <h1 className="text-2xl font-semibold tracking-tight">ログイン</h1>
            <p className="text-sm text-muted-foreground">
              アカウント情報を入力してください
            </p>
          </div>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <label htmlFor="email" className="text-sm font-medium">
                メールアドレス
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                required
                className="h-10 rounded-md border border-input bg-card px-3 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
              />
            </div>

            <div className="flex flex-col gap-2">
              <label htmlFor="password" className="text-sm font-medium">
                パスワード
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  required
                  className="h-10 w-full rounded-md border border-input bg-card px-3 pr-10 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? "パスワードを隠す" : "パスワードを表示"}
                  className="absolute inset-y-0 right-0 flex items-center px-3 text-muted-foreground"
                >
                  {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </div>

            {error && (
              <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
                {error}
              </p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="flex h-10 items-center justify-center gap-2 rounded-md bg-primary text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
            >
              {loading && <Loader2 className="size-4 animate-spin" />}
              {loading ? "ログイン中..." : "ログイン"}
            </button>
          </form>

          <p className="mt-6 text-center text-sm text-muted-foreground">
            アカウントがない場合は管理者にお問い合わせください。
          </p>
        </div>
      </div>
    </div>
  );
}
