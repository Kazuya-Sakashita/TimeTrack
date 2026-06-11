# 開発方針

## 基本原則

1. **小さく進める** — 1 機能 = 1 PR = 1 記事を意識する。
2. **仕様が先、実装は後** — OpenAPI で契約を決めてからコードを書く。
3. **フロントとバックを分離** — OpenAPI 経由でのみつながる。
4. **迷ったら止めて確認** — 推測で実装を進めない。
5. **計画・判断・評価はフレームワークを使う** — 判断根拠を明確にする。詳細は `framework-based-planning.md`。

## ディレクトリ構成（将来像）

```
.
├── frontend/        # Next.js
├── backend/         # Rails API
├── openapi/         # openapi.yaml（仕様の中心）
├── docs/            # 開発ドキュメント（このディレクトリ）
├── .claude/         # Claude Code 用スキル・補助
└── docker-compose.yml
```

## 開発フロー（標準）

```
1. OpenAPI 設計
2. API レビュー
3. Rails 実装
4. Request Spec
5. Next.js 実装
6. E2E / 動作確認
```

## 作業粒度の目安

- 「1 つのエンドポイント」または「1 つの画面」単位まで分解する。
- 1 つの作業で backend と frontend を両方大きく触らない。
- 大きい機能は OpenAPI → backend → test → frontend の順でステップに割る。

## 環境変数・秘密情報

- API URL・鍵・トークンは環境変数で管理する。
- `.env` はコミットしない。サンプルは `.env.example` を用意する。

## レビュー観点（自己チェック）

- OpenAPI と実装は一致しているか
- 認証・認可は要件どおりか
- public_id を使うべき場所で内部 ID が漏れていないか
- Request Spec があるか
- 記事化できる設計メモを残したか
