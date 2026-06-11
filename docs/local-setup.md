# ローカル開発環境の起動

docker compose で db / backend(Rails API) / frontend(Next.js) を起動する。

## 前提

- Docker / Docker Compose が使えること（ホストに Ruby/Node は不要。すべてコンテナ内で動く）

## 手順

```bash
# 1. 環境変数を用意
cp .env.example .env

# 2. backend / frontend のイメージをビルド
docker compose build

# 3. DB を起動し、データベースを作成
docker compose up -d db
docker compose run --rm backend bin/rails db:prepare

# 4. 全サービス起動
docker compose up -d
```

## 動作確認（Walking Skeleton）

- backend ヘルスチェック: <http://localhost:3000/health> → `{"status":"ok","db":"ok"}`
- frontend 確認ページ: <http://localhost:3001/> → 「Backend 疎通 OK」と表示されれば
  frontend → backend → db が全部つながっている。

## ポート

| サービス | URL |
|---|---|
| frontend (Next.js) | <http://localhost:3001> |
| backend (Rails API) | <http://localhost:3000> |
| db (PostgreSQL) | localhost:5432 |

## テスト（backend）

```bash
docker compose run --rm -e RAILS_ENV=test backend bundle exec rspec
```

## よく使うコマンド

```bash
docker compose logs -f backend     # ログ追従
docker compose run --rm backend bin/rails console   # Rails コンソール
docker compose down                # 停止（DB データは volume に残る）
docker compose down -v             # 停止 + DB データ削除
```
