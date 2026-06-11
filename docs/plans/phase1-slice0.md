# Phase1 / Slice 0 — 基盤構築 詳細計画

> `framework-based-planning.md` に従い Walking Skeleton ＋ 依存順タスク分解 ＋ Impact/Effort で立案。
> 親計画: `phase1.md`（Slice 0）。対応 Issue: #2

## ゴール

機能ではなく **「全レイヤーを貫く1本の疎通線（Walking Skeleton）を通すこと」**。

疎通線: ブラウザ（Next.js 確認ページ）→ `GET /health` → Rails が DB 接続確認 → `{ status: "ok", db: "ok" }`。
これで frontend ↔ backend ↔ db ＋ Docker ＋ OpenAPI ＋ テスト基盤がつながった証明になる。

## 技術選定（デフォルト）

| 項目 | 選定 |
|---|---|
| Ruby / Rails | 最新安定版（Rails 8 系・API Mode、`/up` を疎通に活用可） |
| Frontend | V0 準拠: Next.js 16 / React 19 / Tailwind v4 / shadcn base-nova / pnpm |
| 構成 | 単一リポジトリ `frontend/` + `backend/` + `openapi/` |
| public_id | アプリ層 concern（prefix + 一意インデックス） |
| JWT 本実装 | Slice 0 では入れない（OpenAPI に securityScheme の器のみ） |

## タスク（依存順）

- [x] 0-A リポジトリ骨格 & Docker（frontend/ backend/ openapi/、docker-compose.yml、.env.example）
- [x] 0-B backend: Rails 8.1 API Mode 生成（Docker Ruby 3.3、DB=postgresql）
- [x] 0-C PostgreSQL 接続（docker-compose 経由、`rails db:prepare` で dev/test 作成）
- [x] 0-D ヘルスチェック疎通 `GET /health`（DB 接続確認して JSON 応答）← Walking Skeleton の背骨
- [x] 0-E OpenAPI 雛形（info / servers / Error スキーマ / bearer JWT securityScheme / /health）
- [x] 0-F public_id の仕組み（PublicId 生成 + HasPublicId concern + PublicIdMigration ヘルパ + 単体テスト）
- [x] 0-G テスト基盤（RSpec + FactoryBot + Pundit 導入、/health の Request Spec 緑）
- [x] 0-H frontend: Next.js 16 生成 & 疎通（V0 準拠、API URL を env 化、確認ページで疎通 OK 表示）
- [ ] 0-I（Could）CI 最小（GitHub Actions: rspec / lint）← 次スライス前に判断

## 実装メモ（記事素材）

- ホスト Ruby が 2.7.7 のため backend は Docker(Ruby 3.3)+Rails 8.1 で生成・実行。
- `DATABASE_URL` は test 環境まで dev DB を指してしまうため使わず、`POSTGRES_*` + `DATABASE_HOST` の明示設定で dev/test を分離。
- public_id は生成ロジック（PublicId）と concern（HasPublicId）を分離。マイグレーションヘルパは定数衝突回避のため別名前空間 `PublicIdMigration`。
- Walking Skeleton の疎通: frontend は Server Component から `API_INTERNAL_URL`(docker network)で backend を叩く。ブラウザ向けは `NEXT_PUBLIC_API_BASE_URL`。
- ハマり: ① pnpm 11 の supply-chain ポリシーで当日公開パッケージが弾かれ → `packageManager` を pnpm@10 に固定。② Rails 8 の Host Authorization が docker サービス名 `backend` をブロック → `config.hosts << "backend"`。

## 着手順

`0-A → 0-B → 0-C → 0-D → 0-E → 0-F → 0-G → 0-H →（0-I）`
0-D を最優先の到達点に置く。0-I は Effort 対 Impact が低く Could。

## 完了の定義（DoD）

1. `docker compose up` で db / backend / frontend が起動
2. 確認ページから `GET /health` を呼び `db: ok` が表示（Walking Skeleton 完走）
3. `openapi/openapi.yaml` 雛形あり（Error / securityScheme / /health）
4. public_id 生成 concern があり単体テスト緑
5. `rspec` 実行可、/health の Request Spec 緑
6. 起動手順を docs/README に1段落
