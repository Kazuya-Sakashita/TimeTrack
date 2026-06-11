# Phase1 / Slice 4 — 勤怠一覧 詳細計画

> 親計画: `phase1.md`（Slice 4）。対応 Issue: #6

## ゴール

ログイン中ユーザーが自分の勤怠履歴を一覧（ページング）で確認できる。

## 設計判断

| 項目 | 選定 | 理由 |
|---|---|---|
| 取得範囲 | 自分の勤怠のみ（`policy_scope`） | 認可を Pundit Scope に集約。他人の勤怠を見せない |
| 並び順 | work_date 降順 | 新しい日付が上 |
| ページング | page / perPage + pagination メタ | 件数増加に対応。perPage は 1..100 にクランプ |
| レスポンス | `{ attendances: [...], pagination: {...} }` | 一覧 + メタを明示 |

## タスク

- [x] 4-A OpenAPI: `GET /attendances`（query: page, perPage）+ `AttendanceList` / `Pagination` スキーマ
- [x] 4-B AttendancePolicy::Scope（自分の勤怠のみ）
- [x] 4-C AttendancesController#index（policy_scope + ページング + work_date 降順）+ ルート
- [x] 4-D Request Spec（自分のみ / ページング / 降順 / 401）+ Policy Spec（create?/update?/Scope）計30 examples 緑
- [x] 4-E frontend: `/history` 画面（テーブル + status バッジ + ページング）+ dashboard 導線

## 実装メモ（記事素材）

- 認可を `policy_scope(Attendance)` に集約し「自分の勤怠のみ」を保証（Pundit Scope）。Request Spec で他人の勤怠が混ざらないことを検証。
- ページングは page/perPage（perPage は 1..100 にクランプ）+ pagination メタ（total/totalPages）。
- frontend: status-badge コンポーネントを新設（勤務中=primary パルス / 退勤済=muted）。format ヘルパ（時刻/日付/勤務時間）を lib/format.ts に共通化し dashboard とも共用。

## 完了の定義（DoD）

1. OpenAPI に index 定義済み
2. Request Spec 緑（自分のみ / ページング / 401）+ Policy Spec
3. レスポンスは public_id（内部 id 非公開）
4. /history で自分の勤怠一覧が表示される
