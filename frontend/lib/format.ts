// 日時・勤務時間の表示整形（JST 前提）。

export function formatTime(iso: string | null): string {
  if (!iso) return "--:--";
  return new Date(iso).toLocaleTimeString("ja-JP", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("ja-JP", {
    month: "long",
    day: "numeric",
    weekday: "short",
  });
}

export function formatMinutes(min: number | null): string {
  if (min == null) return "--";
  return `${Math.floor(min / 60)}時間${min % 60}分`;
}
