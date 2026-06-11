import type { Attendance } from "@/lib/api";

const styles: Record<Attendance["status"], string> = {
  working: "bg-primary/10 text-primary",
  on_break: "bg-warning/15 text-warning-foreground",
  finished: "bg-muted text-muted-foreground",
};

const labels: Record<Attendance["status"], string> = {
  working: "勤務中",
  on_break: "休憩中",
  finished: "退勤済",
};

export function AttendanceStatusBadge({
  status,
}: {
  status: Attendance["status"];
}) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${styles[status]}`}
    >
      {status === "working" && (
        <span className="mr-1 inline-block size-1.5 animate-pulse rounded-full bg-primary" />
      )}
      {labels[status]}
    </span>
  );
}
