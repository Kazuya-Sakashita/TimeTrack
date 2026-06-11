import { redirect } from "next/navigation";

// ルートはダッシュボードへ。未認証なら /dashboard 側で /login にリダイレクトする。
export default function Home() {
  redirect("/dashboard");
}
