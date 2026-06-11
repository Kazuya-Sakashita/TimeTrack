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
  status: "working" | "finished";
};

export async function clockIn(token: string): Promise<Attendance> {
  const res = await fetch(`${BASE}/attendances/clock-in`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const data = await res.json().catch(() => null);
    throw new Error(data?.error?.message ?? "出勤打刻に失敗しました");
  }
  return res.json();
}

export async function clockOut(token: string): Promise<Attendance> {
  const res = await fetch(`${BASE}/attendances/clock-out`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const data = await res.json().catch(() => null);
    throw new Error(data?.error?.message ?? "退勤打刻に失敗しました");
  }
  return res.json();
}

export async function logout(token: string): Promise<void> {
  await fetch(`${BASE}/auth/logout`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}` },
  });
}
