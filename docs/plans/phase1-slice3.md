# Phase1 / Slice 3 — 退勤打刻 詳細計画

> 親計画: `phase1.md`（Slice 3）。対応 Issue: #5

## ゴール

出勤中のユーザーが「退勤」を打刻でき、勤務時間が算出・表示される。

## 設計判断

| 項目 | 選定 | 理由 |
|---|---|---|
| 操作 | 本日の working レコードを finished に更新（200） | 既存レコードの更新（作成ではない） |
| 勤務時間 | `clock_out_at - clock_in_at`（分） | Slice 3 では休憩控除なし（休憩は Slice 5 で控除） |
| ガード | 未出勤→422 / 退勤済→422 | 不正な状態遷移を防ぐ |
| 認可 | AttendancePolicy#update?（自分の打刻のみ） | 認可は Pundit に集約 |

## タスク

- [x] 3-A OpenAPI: `POST /attendances/clock-out` + `Attendance.workMinutes`
- [x] 3-B Attendance#worked_minutes（勤務時間算出）
- [x] 3-C AttendancesController#clock_out + AttendancePolicy#update? + ルート
- [x] 3-D Request Spec（200 / 未出勤422 / 二重退勤422 / 未認証401）計24 examples 緑
- [x] 3-E frontend: 退勤ボタン + 勤務時間表示（working→退勤 / finished→勤務時間）

## 実装メモ（記事素材）

- 退勤は本日レコードの更新（200）。`worked_minutes = (clock_out - clock_in)/60` を floor。休憩控除は Slice 5。
- 状態遷移ガード: 未出勤→422 not_clocked_in、退勤済→422 already_clocked_out。
- Pundit は `authorize attendance, :update?`。Policy は own? で create?/update? を共通化。
- frontend は status で出勤/退勤ボタンを出し分け（working=退勤[赤], なし=出勤[青], finished=勤務時間表示）。

## 完了の定義（DoD）

1. OpenAPI に clock-out / workMinutes 定義済み
2. Request Spec 緑（200 / 422 / 401）
3. レスポンスは public_id
4. ダッシュボードから退勤でき、勤務時間が表示される
