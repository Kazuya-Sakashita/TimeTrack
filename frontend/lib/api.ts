// backend(Rails API) との通信。OpenAPI の契約に対応する。
const BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3000";

export type Role = "employee" | "manager" | "admin";

export type ApiUser = {
  id: string; // public_id
  email: string;
  name: string;
  role: Role;
};

export type LoginResult = { token: string; user: ApiUser };

export async function login(email: string, password: string): Promise<LoginResult> {
  const res = await fetch(`${BASE}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => null);
    throw new Error(data?.error?.message ?? "ログインに失敗しました");
  }
  return res.json();
}

export async function fetchMe(token: string): Promise<ApiUser> {
  const res = await fetch(`${BASE}/me`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error("セッションが無効です");
  return res.json();
}

export type Attendance = {
  id: string;
  workDate: string;
  clockInAt: string | null;
  clockOutAt: string | null;
  workMinutes: number | null;
  breakMinutes: number;
  openBreakId: string | null;
  status: "working" | "on_break" | "finished";
};

export type Pagination = {
  page: number;
  perPage: number;
  total: number;
  totalPages: number;
};

export type AttendanceList = {
  attendances: Attendance[];
  pagination: Pagination;
};

export async function fetchAttendances(
  token: string,
  page = 1,
  perPage = 20,
): Promise<AttendanceList> {
  const res = await fetch(
    `${BASE}/attendances?page=${page}&perPage=${perPage}`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) throw new Error("勤怠の取得に失敗しました");
  return res.json();
}

// 勤怠系の共通リクエスト。リソース中心の契約に対応する。
async function attendanceRequest(
  token: string,
  method: "POST" | "PATCH",
  path: string,
  fallbackMessage: string,
  body?: unknown,
): Promise<Attendance> {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const data = await res.json().catch(() => null);
    throw new Error(data?.error?.message ?? fallbackMessage);
  }
  return res.json();
}

// 出勤 = 勤怠の作成
export function clockIn(token: string): Promise<Attendance> {
  return attendanceRequest(token, "POST", "/attendances", "出勤打刻に失敗しました");
}

// 退勤 = 勤怠の状態更新
export function clockOut(token: string, attendanceId: string): Promise<Attendance> {
  return attendanceRequest(
    token,
    "PATCH",
    `/attendances/${attendanceId}`,
    "退勤打刻に失敗しました",
    { status: "finished" },
  );
}

// 休憩開始 = breaks の作成
export function breakStart(token: string, attendanceId: string): Promise<Attendance> {
  return attendanceRequest(
    token,
    "POST",
    `/attendances/${attendanceId}/breaks`,
    "休憩開始に失敗しました",
  );
}

// 休憩終了 = breaks の更新
export function breakEnd(
  token: string,
  attendanceId: string,
  breakId: string,
): Promise<Attendance> {
  return attendanceRequest(
    token,
    "PATCH",
    `/attendances/${attendanceId}/breaks/${breakId}`,
    "休憩終了に失敗しました",
  );
}

export async function logout(token: string): Promise<void> {
  await fetch(`${BASE}/auth/logout`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}` },
  });
}
