# デザインシステム

TimeTrack のフロントエンドのデザインは、**V0 (v0.app) で生成したプロトタイプを基準** とする。
今後 UI を作る・直すときは、まずこの基準に合わせる。

## ソース

- 生成物の場所: `~/Downloads/time-track`（V0 エクスポート、`time-track.zip` も同梱）
- 位置づけ: **デザイン / UI の基準**。アーキテクチャの正典ではない。
  - API の契約は引き続き OpenAPI が正（`api-driven-development.md`）。
  - 外部 ID は引き続き `public_id`（`database-policy.md`）。
  - V0 の `lib/data.ts` はモックデータ。実装時は TanStack Query で実 API に置き換える。
- frontend 着手時に、この生成物を `frontend/` に取り込む（今は未取り込み）。

## 取り込み方針

**基本は取り込む。ただし丸ごとコピーせず、都度ベストな形にリファクタリングしながら段階的に取り込む。**

- V0 生成物は「完成品」ではなく「良質なたたき台」として扱う。
- 取り込む単位は機能 / 画面ごと（一気に全部入れない。`development-policy.md` の作業粒度に従う）。
- 取り込む際に必ず見直す観点:
  - モックデータ依存（`lib/data.ts`）を実 API（OpenAPI + TanStack Query）に置き換える。
  - 内部 id 依存を `public_id` に直す。
  - フォームは React Hook Form + Zod に寄せる。
  - 型を OpenAPI 由来に統一し、`any` を排除する。
  - 重複・不要コンポーネントを整理し、命名・構成をプロジェクト規約に合わせる。
- 一方で **デザイン（トークン・レイアウト・見た目・UX）は基準として維持** する。リファクタは構造・実装の話であり、見た目を勝手に変えない。
- 大きく作り変える判断をするときは `framework-based-planning.md` に従う（例: Impact/Effort で取り込み順を決める）。

## 技術スタック（V0 生成物に準拠）

- Next.js 16 (App Router) / React 19 / TypeScript
- Tailwind CSS v4（`@import 'tailwindcss'` + `@theme inline`、設定は `app/globals.css`）
- shadcn/ui（style: `base-nova`、`@base-ui/react` ベース、CSS 変数モード、baseColor: neutral）
- アイコン: lucide-react
- トースト: sonner / グラフ: recharts / カレンダー: react-day-picker + date-fns
- テーマ切替: next-themes（light / dark）
- フォント: Geist Sans（本文・見出し）/ Geist Mono（時刻・数値）

## カラートークン（OKLCH、light / dark 両対応）

| 役割 | 色 | 用途 |
|------|----|----|
| primary | 青 `#2563EB` | 主要アクション・出勤中・リンク |
| success | 緑 `#22C55E` | 承認・正常・勤務中 |
| warning | 橙 `#F59E0B` | 保留・遅刻・休憩中 |
| destructive | 赤 `#EF4444` | 退勤・却下・欠勤・破壊的操作 |
| neutral | グレー系 | 背景・枠・補助テキスト |

- 角丸: `--radius: 0.625rem`（sm〜4xl を係数で派生）
- チャート色は chart-1〜5 を使用。
- 透明度付きトーン（例: `bg-primary/10`, `bg-success/15`）でバッジ・アイコン背景を表現する。

## レイアウト

`components/app-shell.tsx` の `AppShell` が全画面の枠。

- 折りたたみ可能なアイコンサイドバー（`collapsible="icon"`）
- ロール別ナビ（`lib/nav.ts` の `navByRole`）: `employee` / `manager` / `admin`
- ブランド（Clock3 アイコン + "TimeTrack"）、ビュー切替、フッターにユーザーメニュー
- ヘッダー: `sticky top-0 h-16`、`backdrop-blur`、トリガー + タイトル + 通知ベル
- メイン: `p-4 md:p-6`

ページは `<AppShell role title breadcrumb>{...}</AppShell>` で包む。

## 共通コンポーネント

| コンポーネント | 役割 |
|---|---|
| `app-shell` | サイドバー + ヘッダーの全体レイアウト |
| `stat-card` | 数値サマリーカード（`tone`: default/primary/success/warning/danger, `trend`） |
| `status-badge` | `AttendanceStatusBadge` / `RequestStatusBadge`（状態色 + 出勤中はパルス点） |
| `clock-widget` | 打刻ウィジェット（時計 + 出勤/退勤/休憩開始/終了 + 本日の経過） |
| `attendance-calendar` | 勤怠カレンダー |
| `auth-brand-panel` | ログイン系画面のブランドパネル |

`components/ui/*` は shadcn/ui の標準コンポーネント群。

## UI 規約

- 表示言語は日本語（`<html lang="ja">`）。
- 時刻・時間・件数などの数値は `font-mono` + `tabular-nums`（桁ぞろえ）。
- 状態は「色付きドット + ラベル」で表す。進行中は `animate-pulse`。
- 状態の色対応はトークンに従う（出勤中=primary, 承認=success, 保留=warning, 却下/欠勤=destructive）。
- 余白・角丸・トーンはトークン経由で指定し、生の色をハードコードしない。

## 状態の語彙（UI 表示用 / 正典は OpenAPI）

- `AttendanceStatus`: present / completed / late / absent / leave / holiday
- `RequestStatus`: pending / approved / rejected
- `RequestType`: clock_in / clock_out / break / overtime / leave

> これらは UI 表示の参考。実際の値・遷移は OpenAPI とバックエンド実装で確定する。

## 画面一覧（V0 生成物のルート）

- 認証: `/login`, `/forgot-password`
- 従業員: `/dashboard`, `/history`, `/history/[id]`, `/requests`, `/requests/new`, `/profile`
- マネージャー: `/manager`, `/manager/employees`, `/manager/attendance`, `/manager/requests`, `/manager/reports`
- 管理者: `/admin`, `/admin/users`, `/admin/departments`, `/admin/work-rules`, `/admin/settings`

## 関連

- `.claude/skills/next-frontend.md` — フロント実装手順
- `CLAUDE.md` の「Next.js 実装ルール」
