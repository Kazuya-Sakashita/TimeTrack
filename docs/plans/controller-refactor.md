# リファクタ計画 — 勤怠 API をリソース中心へ

> `framework-based-planning.md` に従い REST 設計原則 / Contract First / Impact-Effort で立案。
> 方針: `backend-controller-design.md`

## 背景（調査結果）

Phase1 の勤怠打刻 API は動詞ベースの独自アクションで、Controller 設計方針に未準拠。

| 現状（違反） | 操作 |
|---|---|
| POST /attendances/clock-in | 出勤 |
| POST /attendances/clock-out | 退勤 |
| POST /attendances/break-start | 休憩開始 |
| POST /attendances/break-end | 休憩終了 |

他は準拠済み: `GET /attendances`(index)、`auth/sessions#create/destroy`（セッション=RESTful）、`me#show`（単数の便宜エンドポイント）。

## 目標（Contract First: 新しい契約）

```text
出勤      POST  /attendances                      (create)
退勤      PATCH /attendances/:id                   {"status":"finished"}
一覧      GET   /attendances                       (index, 既存)
詳細      GET   /attendances/:id                   (show, 追加)
休憩開始  POST  /attendances/:attendance_id/breaks (create)
休憩終了  PATCH /attendances/:attendance_id/breaks/:id   (update; ended_at をセット)
```

- `:id` / `:attendance_id` は public_id。
- 状態遷移ガード（未出勤/退勤済/二重休憩/休憩外終了）は維持し 422。
- 認可は AttendancePolicy#create?/update? と BreakPolicy（または attendance 経由）に集約。

## 優先順位（Impact / Effort）

| 項目 | Impact | Effort | 備考 |
|---|---|---|---|
| 勤怠の動詞 → create/update | 高 | 中 | 方針違反の中核。最優先 |
| 休憩 → breaks サブリソース | 高 | 中 | 別リソース化の代表例 |
| 認証 → `resource :session`（POST/DELETE /session） | 低 | 小 | 任意。意味的には既に RESTful。今回は見送り可 |

## タスク（OpenAPI → backend → spec → frontend → docs）

- [x] R-1 OpenAPI 改訂（create/update/サブリソースへ）
- [x] R-2 routes を `resources` ベースへ（member/collection 不使用）
- [x] R-3 AttendancesController を index/show/create/update に再編
- [x] R-4 BreaksController を新設（create/update）
- [x] R-5 状態遷移ロジックを Attendance モデルへ移動（clock_out!/start_break!/finish_break!）
- [x] R-6 Request Spec を新エンドポイントに合わせ改訂（attendances + breaks。計41 examples 緑）
- [x] R-7 frontend lib/api.ts と dashboard を新契約に追従（tsc 緑）
- [x] R-8 README / docs を更新（Issue #16）

## 実装メモ（記事素材）

- 認可は break も「親 attendance の update」とみなし `authorize attendance, :update?` に集約。
- 休憩は親 Attendance の最新状態（`openBreakId` 含む）を返す方針で、フロントは Attendance 1 つを保持。
- `not_clocked_in`（未出勤）は「存在しないリソースへの操作」となり 404 で自然に表現（旧 422 から変更）。

## 完了の定義（DoD）

1. 動詞ベースのルート/アクションが無い（レビュー観点を満たす）
2. OpenAPI・README・docs が新契約と一致
3. Request Spec 緑（正常 + 異常 + 認可）
4. frontend が新契約で動作（出勤→休憩→退勤→履歴）

## 留意点

- 公開済みの契約変更（破壊的）。Phase1 はまだ自分のみ利用のため一括移行で可。
- 退勤の表現は `PATCH /attendances/:id {"status":"finished"}`（状態を送る）。実装は working→finished のみ許可。
