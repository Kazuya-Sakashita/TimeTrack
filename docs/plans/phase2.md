# Phase2 実装計画 — 修正申請・承認フロー

> `framework-based-planning.md`（MoSCoW / RICE / Vertical Slice + INVEST）で立案。
> 設計は `backend-controller-design.md`（リソース中心）に準拠。

## ゴール

従業員が打刻の修正を申請し、管理者が承認/却下でき、承認内容が勤怠に反映される。

## スコープ（MoSCoW）

| 区分 | 項目 |
|---|---|
| Must | 修正申請モデル / 申請作成 / 自分の申請一覧・詳細 / 管理者の申請一覧 / 承認・却下（status 更新）/ 承認時に Attendance へ反映 / ロール認可 |
| Should | 申請フォーム UI（従業員）/ 承認画面 UI（管理者）/ 却下コメント |
| Could | 申請の取消（withdraw）/ 種別拡張（残業・休暇）/ 一覧の絞り込み |
| Won't（Phase2では） | Slack 通知 / 月次集計 / AI 分析 / CSV 出力 |

## リソース設計（リソース中心）

`resources :attendance_change_requests, only: %i[index show create update]`

| 操作 | エンドポイント |
|---|---|
| 申請作成 | `POST /attendance_change_requests` |
| 一覧 | `GET /attendance_change_requests`（policy_scope: employee=自分 / manager・admin=全件） |
| 詳細 | `GET /attendance_change_requests/:id` |
| 承認・却下 | `PATCH /attendance_change_requests/:id { status, comment }`（状態更新。動詞 API は使わない） |

> 承認/却下を `/approve`・`/reject` のような動詞アクションにしないことが本フェーズの設計上の肝。

## スライス分割（Vertical Slice）

- **Slice 6 — 修正申請の作成・閲覧（従業員）**
  - `AttendanceChangeRequest` モデル + migration
    （public_id `acr_`、申請者 user、対象 attendance、proposed_clock_in_at / proposed_clock_out_at、reason、status enum: pending/approved/rejected、reviewer / reviewed_at / review_comment）
  - `POST` 作成 / `GET` 一覧（自分）/ `GET /:id` 詳細
  - 従業員 UI: 申請フォーム + 自分の申請一覧（status バッジ）
- **Slice 7 — 承認・却下（管理者）＋ 認可の本格化**
  - `PATCH /:id { status: approved|rejected, comment }`
  - 承認時に対象 `Attendance` の時刻を反映（Service で適用・勤務時間再計算）
  - ロール認可: manager/admin のみ承認可・申請者は自分の申請を承認不可、Scope で manager/admin は全件
  - 管理者 UI: 申請一覧 + 承認/却下（コメント）
- **Slice 8（Should/Could）— 取消・絞り込み・種別拡張**（任意）

## 優先順位（RICE）

| 順 | スライス | R | I | C | E | RICE |
|---|---|---|---|---|---|---|
| 1 | Slice 6 申請作成・閲覧 | 4 | 3 | 0.9 | 3 | 3.6 |
| 2 | Slice 7 承認・却下＋反映 | 4 | 3 | 0.8 | 4 | 2.4 |
| 3 | Slice 8 取消・絞り込み | 2 | 2 | 0.7 | 3 | 0.9 |

**着手順: 6 → 7 →（8）**

## 主要な設計判断

1. 申請対象は既存 `Attendance` への時刻修正を MVP とする（Attendance 無しの日の申請は Could）。
2. 承認/却下は `PATCH /:id { status }`（リソース中心）。
3. 認可: 申請者は自分の申請のみ作成/閲覧、承認は manager/admin のみ・自分の申請は承認不可。

## スライス完了の定義（DoD）

各スライスで: OpenAPI 定義 / Request Spec（正常 + 異常 + 認可）/ public_id / Policy Spec（ロール別）/ UI 連携 / 設計メモ。
