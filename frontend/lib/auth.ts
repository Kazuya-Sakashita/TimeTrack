// JWT を localStorage に保持する簡易ストア。
// 注: Slice 1 の最小実装。将来は httpOnly Cookie 等への移行を検討（design/security 方針）。
const KEY = "timetrack_token";

export const tokenStore = {
  get(): string | null {
    if (typeof window === "undefined") return null;
    return window.localStorage.getItem(KEY);
  },
  set(token: string): void {
    window.localStorage.setItem(KEY, token);
  },
  clear(): void {
    window.localStorage.removeItem(KEY);
  },
};
