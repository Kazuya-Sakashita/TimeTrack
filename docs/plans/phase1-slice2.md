# Phase1 / Slice 2 — 出勤打刻 詳細計画

> 親計画: `phase1.md`（Slice 2）。対応 Issue: #4

## ゴール

ログイン中ユーザーが「出勤」を打刻でき、本日の出勤記録が作られる。

## 設計判断

| 項目 | 選定 | 理由 |
|---|---|---|
| 単位 | 1人1日1レコード（`(user_id, work_date)` 一意） | 二重打刻を防ぐ |
| TZ | `Asia/Tokyo`（DB は UTC 保存） | 日本の勤怠アプリ前提。「本日」を正しく判定 |
| status | working / finished（enum） | 退勤(Slice 3)で finished に |
| 認可 | AttendancePolicy#create?（自分の打刻のみ） | 認可は Pundit に集約 |
| レスポンス | camelCase（workDate/clockInAt 等）、id は public_id | フロント親和・内部 id 非公開 |

## タスク

- [x] 2-A OpenAPI: `POST /attendances/clock-in` + `Attendance` スキーマ
- [x] 2-B Attendance モデル + migration（public_id, user, work_date, clock_in_at, clock_out_at, status, (user_id,work_date)一意）
- [x] 2-C AttendancesController#clock_in + AttendancePolicy + AttendanceSerializer + ルート
- [x] 2-D Request Spec（201 / 二重打刻 422 / 未認証 401）20 examples 緑
- [x] 2-E frontend: 出勤ボタン（dashboard、打刻時刻・勤務中表示）

## 実装メモ（記事素材）

- TZ を `Asia/Tokyo` に設定（DB は UTC、`Date.current`/`Time.current` が JST 基準に）。レスポンスは `+09:00`。
- Pundit `authorize` はアクション名から `clock_in?` を探すため、`authorize attendance, :create?` と権限名を明示。
- 二重打刻は `(user_id, work_date)` 一意制約 + 事前 exists? チェックで 422。

## 完了の定義（DoD）

1. OpenAPI に clock-in 定義済み
2. Request Spec 緑（201 / 422 / 401）
3. レスポンスは public_id（内部 id 非公開）
4. ダッシュボードから出勤打刻でき、打刻時刻が表示される
