# Phase1 / Slice 5 — 休憩 詳細計画

> 親計画: `phase1.md`（Slice 5, Should）。対応 Issue: #7

## ゴール

勤務中のユーザーが休憩を開始・終了でき、勤務時間から休憩が控除される。

## 設計判断

| 項目 | 選定 | 理由 |
|---|---|---|
| 休憩の保持 | `attendance_breaks` テーブル（has_many） | 1日複数回の休憩を正規化して保持 |
| status | working / finished / **on_break** | 既存 working=0/finished=1 を維持し on_break=2 を追加（データ非破壊） |
| 勤務時間 | `worked_minutes = (clock_out - clock_in) - break_minutes` | 休憩を控除 |
| ガード | 未出勤/退勤済/二重休憩/休憩外終了 → 422 | 不正な状態遷移を防ぐ |
| 認可 | AttendancePolicy#update?（自分の打刻のみ） | 認可は Pundit に集約 |

## タスク

- [x] 5-A OpenAPI: `break-start`/`break-end` + status に on_break + `Attendance.breakMinutes`
- [x] 5-B AttendanceBreak モデル + migration（public_id brk_, attendance, started_at, ended_at, open scope）
- [x] 5-C Attendance#break_minutes / worked_minutes 控除（休憩控除後）
- [x] 5-D AttendancesController#break_start/#break_end + render_error ヘルパ + ルート
- [x] 5-E Request Spec（200 / not_clocked_in / already_on_break / not_on_break / 401）+ model spec（控除）計39 examples 緑
- [x] 5-F frontend: 休憩開始・終了ボタン + 休憩中表示（warning トークン追加、status-badge に on_break）

## 実装メモ（記事素材）

- 休憩は `attendance_breaks`（has_many）で正規化。1日複数回・open scope（ended_at nil）で進行中を判定。
- enum は既存整数を壊さないよう `working:0, finished:1` を維持し `on_break:2` を追加。
- `worked_minutes = (clock_out - clock_in) - break_minutes`（0 未満は 0 にクランプ）。
- 状態遷移ガード: 未出勤/退勤済/二重休憩/休憩外終了 → 422。
- frontend: status で4状態のボタンを出し分け。warning カラートークンを globals.css に追加。

## 完了の定義（DoD）

1. OpenAPI に break-start/break-end / breakMinutes 定義済み
2. Request Spec 緑 + 勤務時間控除の検証
3. レスポンスは public_id
4. ダッシュボードから休憩開始・終了でき、状態が反映される
