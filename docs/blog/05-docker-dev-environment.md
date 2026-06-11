# Docker だけで Rails 8 + Next.js 16 を動かす開発環境

> TimeTrack（勤怠管理システム）の開発記録。
> 構成: Next.js + Rails API + PostgreSQL。起動手順は [`docs/local-setup.md`](../local-setup.md)。

## 結論（PREP の P）

ホストに Ruby も Node も入れず、**Docker Compose だけ**で `db`（PostgreSQL）/ `backend`（Rails 8）/ `frontend`（Next.js 16）を起動できるようにした。
最初に通したのは機能ではなく **「frontend → backend → db を貫く1本の疎通線（Walking Skeleton）」**。

## 課題

- ホストの Ruby が古く（2.7 系）、Rails 8（Ruby 3.2+ 必須）が動かない
- 「自分の環境では動く」を避け、誰でも同じ手順で起動できるようにしたい
- 最初から全機能を作るのではなく、**全レイヤーがつながることを最初に証明**したい

## 解決

### docker-compose（3 サービス）

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 5s
      retries: 5

  backend:
    build: { context: ./backend, dockerfile: Dockerfile.dev }
    command: bin/rails server -b 0.0.0.0 -p 3000
    environment:
      DATABASE_HOST: db
      POSTGRES_USER: ${POSTGRES_USER}
      # ...
    ports: ["3000:3000"]
    volumes: ["./backend:/app"]            # コードは bind mount（ライブリロード）
    depends_on:
      db: { condition: service_healthy }   # DB が healthy になってから起動

  frontend:
    build: { context: ./frontend, dockerfile: Dockerfile.dev }
    environment:
      NEXT_PUBLIC_API_BASE_URL: http://localhost:3000   # ブラウザ→backend
      API_INTERNAL_URL: http://backend:3000             # Server Component→backend
    ports: ["3001:3000"]
    volumes: ["./frontend:/app", "/app/node_modules"]   # node_modules はコンテナ側を保持
    depends_on: [backend]
```

### ホストに Ruby が無くても Rails アプリを生成

`rails new` すらコンテナで実行する。

```bash
docker run --rm -v "$PWD/backend":/app -w /app ruby:3.3 \
  bash -c "gem install rails -v '~> 8.0' && rails new . --api --database=postgresql --skip-git"
```

開発用 Dockerfile は素直に。gem はコード bind mount の外（イメージ層）に入れる。

```dockerfile
# backend/Dockerfile.dev
FROM ruby:3.3
RUN apt-get update -qq && apt-get install -y --no-install-recommends postgresql-client
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install        # gem は /usr/local/bundle（/app の外）
COPY . .
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
```

### 起動の流れ

```bash
cp .env.example .env
docker compose build
docker compose up -d db
docker compose run --rm backend bin/rails db:prepare
docker compose up -d
```

- backend ヘルスチェック: <http://localhost:3000/health> → `{"status":"ok","db":"ok"}`
- frontend 確認ページ: <http://localhost:3001/> → 「Backend 疎通 OK」

frontend は Server Component から `API_INTERNAL_URL`（= `http://backend:3000`）で backend を呼び、
backend は DB に接続して `{status, db}` を返す。これが通れば全レイヤーがつながった証明になる。

## ハマったこと・学び

1. **dev/test の DB を分離する**
   `DATABASE_URL` を1本にすると test 環境まで開発 DB を指してしまう。
   `database.yml` で `POSTGRES_*` + `DATABASE_HOST` を使い、development と test を別 DB にした。

2. **pnpm の版を固定する**
   コンテナの corepack が pnpm 11 を取りに行き、新しい supply-chain ポリシーで
   「当日公開されたパッケージ」が弾かれてビルド失敗。
   `package.json` の `packageManager` を `pnpm@10.x` に固定して解決。

3. **Rails 8 の Host Authorization**
   frontend（Server Component）が `http://backend:3000` を叩くと、Rails が
   `Blocked hosts: backend:3000` で 403。development で `config.hosts << "backend"` を許可。

4. **新しい npm 依存を足したら anonymous volume を作り直す**
   `node_modules` を匿名ボリュームで保持しているため、依存追加後の `up` では
   古い `node_modules` が新イメージを覆って `Module not found`。
   `docker compose up -d --renew-anon-volumes frontend` で再作成する。

5. **ブラウザ用と内部用で API URL を分ける**
   ブラウザからは `localhost:3000`、コンテナ間（Server Component）は `backend:3000`。
   `NEXT_PUBLIC_API_BASE_URL` と `API_INTERNAL_URL` を使い分ける。

## まとめ

- ホストを汚さず **Docker Compose だけ**で 3 サービスを起動。`rails new` もコンテナで実行。
- 最初に **Walking Skeleton**（frontend→backend→db）を通し、全レイヤーの結線を先に証明する。
- ハマりどころは「dev/test DB 分離」「pnpm 版固定」「Host Authorization」「anonymous volume」「API URL の内外分離」。

関連記事:
[03. API駆動開発の進め方](03-api-driven-development.md)
