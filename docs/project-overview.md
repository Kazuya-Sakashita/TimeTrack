# プロジェクト概要

## TimeTrack とは

従業員の出退勤を管理する Web アプリケーション。
打刻・勤怠履歴・修正申請・承認フロー・月次集計などを扱う。

## このプロジェクトのねらい（設計意図）

個人開発はフロントとバックを同時に作り、仕様が曖昧になりがち。
TimeTrack では **API 駆動開発** を採用し、OpenAPI を唯一の仕様書として
「先に契約を決めてから実装する」流れを実践する。これにより:

- フロント / バックを独立して開発・テストできる
- 型安全な開発ができる
- 仕様変更の影響を OpenAPI で追える
- 一連の設計判断をそのまま技術ブログにできる

## 想定ユーザーとロール

- `employee`（従業員）: 自分の打刻・勤怠確認・修正申請
- `admin`（管理者）: 従業員 / 勤怠一覧、修正申請の承認・却下、月次確認

## 主な機能

- 従業員: ログイン / 出勤・退勤打刻 / 休憩開始・終了 / 勤怠履歴 / 月次確認 / 修正申請
- 管理者: 従業員一覧 / 勤怠一覧 / 修正申請の承認・却下 / 月次確認 / ダッシュボード
- 将来: 有給申請 / Slack 通知 / AI 分析 / CSV 出力 / 異常検知

## システム構成

```
Next.js (Frontend)  ──OpenAPI──▶  Ruby on Rails (API)  ──▶  PostgreSQL
```

## ロードマップ

- Phase1: 認証 / 出勤 / 退勤 / 勤怠一覧
- Phase2: 修正申請 / 承認フロー
- Phase3: 月次集計 / レポート
- Phase4: AI 分析 / Slack 連携

## ドキュメント一覧

- `development-policy.md` — 全体の開発方針と進め方
- `api-driven-development.md` — API 駆動開発の具体フロー
- `backend-controller-design.md` — Controller / API のリソース中心設計方針
- `database-policy.md` — DB 設計と public_id
- `security-policy.md` — 認証・認可
- `testing-policy.md` — テスト戦略
- `blog-strategy.md` — 記事化の方針
- `framework-based-planning.md` — 計画・判断・評価でのフレームワーク利用ルール
- `design-system.md` — フロントエンドのデザイン基準（V0 生成プロトタイプ準拠）
