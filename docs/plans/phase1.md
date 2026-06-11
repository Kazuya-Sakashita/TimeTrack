# Phase1 実装計画

> 計画は `framework-based-planning.md` に従い MoSCoW / RICE / Vertical Slice + INVEST で立案。

## ゴール

**「ログインして出退勤を打刻し、自分の勤怠一覧を見られる」** 最小の縦貫線を完成させる。
Phase1 は縦に薄く・確実に通すことを優先し、承認・集計・管理者機能は Phase2 以降に回す。

## 使用したフレームワーク

- MoSCoW — スコープ仕分け
- RICE — 着手順の客観化
- Vertical Slice + INVEST — Issue 分割（1スライス = 1 PR = 1 記事）

## スコープ（MoSCoW）

| 区分 | 項目 |
|---|---|
| Must | 基盤構築（Rails API + PostgreSQL + Next.js + Docker + OpenAPI 雛形）／JWT 認証（login・logout・me）／出勤打刻／退勤打刻／自分の勤怠一覧 |
| Should | 休憩開始・終了／ログイン画面 UI（V0 取り込み）／ダッシュボード（clock-widget） |
| Could | 勤怠詳細画面／ロール基盤（employee/admin の器）／パスワードリセット画面のガワ |
| Won't（Phase1では） | 修正申請・承認／月次集計／管理者・マネージャー画面／AI 分析／Slack 連携 |

## スライス分割（Vertical Slice）

各スライスは原則 `OpenAPI → レビュー → Rails → Request Spec → Next.js（V0 リファクタ取り込み） → 動作確認` を満たす。

- **Slice 0 — 基盤構築**（横断）
  backend(Rails API Mode) / frontend(Next.js) / PostgreSQL / docker-compose /
  `openapi/openapi.yaml` 雛形（共通エラー形式・security）/ public_id 生成の仕組み
- **Slice 1 — 認証**
  User モデル（role, public_id）/ `POST /auth/login` / `DELETE /auth/logout` / `GET /me` /
  Pundit 下地 / ログイン画面 UI（V0 `/login`）
- **Slice 2 — 出勤打刻**
  Attendance モデル / `POST /attendances/clock-in` / Request Spec / clock-widget（出勤）
- **Slice 3 — 退勤打刻**
  `POST /attendances/clock-out` / 当日勤務時間の算出 / clock-widget（退勤）
- **Slice 4 — 勤怠一覧**
  `GET /attendances`（自分の勤怠・ページング）/ `/history` 画面 / status-badge
- **Slice 5（Should）— 休憩**
  `POST /attendances/break-start` `break-end` / clock-widget（休憩）

## 優先順位（RICE: R×I×C÷E）

| 順 | スライス | R | I | C | E | RICE | 根拠 |
|---|---|---|---|---|---|---|---|
| 1 | Slice 0 基盤 | 5 | 3 | 0.8 | 5 | 2.4 | 全機能の前提 |
| 2 | Slice 1 認証 | 5 | 3 | 0.9 | 4 | 3.4 | 全 API の前提 |
| 3 | Slice 2 出勤打刻 | 3 | 3 | 0.9 | 2 | 4.05 | 中核体験の入口・小さく高価値 |
| 4 | Slice 3 退勤打刻 | 3 | 3 | 0.9 | 2 | 4.05 | 出勤と対・勤務時間算出の起点 |
| 5 | Slice 4 勤怠一覧 | 2 | 3 | 0.85 | 3 | 1.7 | 打刻結果の可視化 |
| 6 | Slice 5 休憩 | 2 | 2 | 0.8 | 2 | 1.6 | Should・中核の上積み |

Slice 0・1 は依存関係上で先行確定。

**着手順: 0 → 1 → 2 → 3 → 4 →（5）**

## スライス完了の定義（Definition of Done）

1. OpenAPI に定義がある（`api-driven-development.md`）
2. Rails 実装がある（Controller 薄く・Pundit 認可・public_id）
3. Request Spec が通る（正常 + 異常 + 認可。`testing-policy.md`）
4. 内部 id が漏れていない
5. 該当 UI を V0 からリファクタ取り込み済み（`design-system.md`）
6. 設計意図・つまずきメモを残した（`blog-strategy.md`）

## 次のアクション

1. Slice 0（基盤構築）の詳細計画を framework-based で分解 → 実装フェーズ開始。
2. 各 Slice を GitHub Issue として管理（1 Slice = 1 Issue = 1 PR = 1 記事）。
