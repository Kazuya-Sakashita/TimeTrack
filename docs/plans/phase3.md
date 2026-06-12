# Phase3 実装計画 — 月次集計・レポート

> `framework-based-planning.md`（MoSCoW / RICE / Vertical Slice + INVEST）で立案。
> 設計は `backend-controller-design.md`（リソース中心）に準拠。

## ゴール

従業員が自分の月次勤怠サマリーを確認でき、管理者が全体/部下の月次を確認できる。

## スコープ（MoSCoW）

| 区分 | 項目 |
|---|---|
| Must | 月次サマリー API（自分・指定年月）/ 従業員の月次画面 / 自分のみ可視（policy_scope） |
| Should | 管理者の月次一覧（全従業員）/ 対象ユーザー指定 / 日別内訳 |
| Could | CSV エクスポート / 前月比・残業アラート |
| Won't（Phase3では） | Slack 通知 / AI 分析（Phase4）/ 給与計算 |

## リソース設計

`monthly_reports`（**読み取り専用・集計は保存せず Attendance から都度算出**）。

| 操作 | エンドポイント |
|---|---|
| 自分の月次 | `GET /monthly_reports/:month`（:month = YYYY-MM） |
| 管理者一覧 | `GET /monthly_reports?month=YYYY-MM`（manager/admin は全員 / 任意で userId 指定） |

## 集計仕様

- 勤務日数 / 総勤務分（休憩控除後）/ 総休憩分 / 残業分（所定超過）/ 日別内訳。
- 残業 = 1日の勤務分が所定（**当面 480 分固定**）を超えた分の合計。所定時間の設定化は別途（勤務ルール）。
- 集計は Service（PORO / Query object）に集約し、Attendance から算出。保存しない。

## スライス分割（Vertical Slice）

- **Slice 9 — 自分の月次サマリー（従業員）**
  - `GET /monthly_reports/:month`、`MonthlyReport` 集計サービス、Serializer
  - 従業員 UI: 月選択 + サマリーカード + 日別内訳
- **Slice 10 — 管理者の月次一覧（manager/admin）**
  - `GET /monthly_reports?month=`（全員）/ `&userId=`（対象指定）
  - ロール認可（自分のみ vs 全員）を Pundit に集約
  - 管理者 UI: 月次一覧テーブル
- **Slice 11（Could）— CSV / 残業アラート**（任意）

## 優先順位（RICE）

| 順 | スライス | R | I | C | E | RICE |
|---|---|---|---|---|---|---|
| 1 | Slice 9 自分の月次 | 4 | 3 | 0.85 | 3 | 3.4 |
| 2 | Slice 10 管理者一覧 | 3 | 3 | 0.8 | 4 | 1.8 |
| 3 | Slice 11 CSV/アラート | 2 | 2 | 0.7 | 3 | 0.9 |

**着手順: 9 → 10 →（11）**

## 主要な設計判断

1. 集計は保存せず Attendance から都度算出（MVP に十分。将来は集計テーブル/キャッシュ）。
2. 残業は所定 480 分/日 超過分（固定値スタート、設定化は別途）。
3. 月の指定はパス `:month`（YYYY-MM）でリソース中心に。

## スライス完了の定義（DoD）

各スライスで: OpenAPI 定義 / Request Spec（正常 + 異常 + 認可）/ public_id / Policy Spec / UI 連携 / 設計メモ。
