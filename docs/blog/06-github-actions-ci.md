# GitHub Actions で rspec / lint / 機密スキャンを多層化する

> TimeTrack（勤怠管理システム）の開発記録。
> 構成: Next.js + Rails API + PostgreSQL（モノレポ）。

## 結論（PREP の P）

モノレポ（`backend/` + `frontend/`）の CI を GitHub Actions で組み、
**テスト（rspec）/ Lint（rubocop・eslint）/ セキュリティ（brakeman・bundler-audit・gitleaks）** を
push と PR ごとに自動実行するようにした。`main` への直接コミットは避け、PR + 緑のチェックを前提にしている。

## 課題

- 手元では緑でも、環境差で CI が落ちる（後述の eager_load 問題など）
- backend と frontend で必要なチェックが違う
- 機密情報（鍵・トークン）の誤コミットを止めたい

## 解決：4 ジョブ構成

```yaml
# .github/workflows/ci.yml（抜粋）
jobs:
  backend-test:        # rspec（PostgreSQL サービス付き）
    services:
      postgres:
        image: postgres:16
        env: { POSTGRES_USER: timetrack, POSTGRES_PASSWORD: timetrack_password, POSTGRES_DB: timetrack_test }
        options: >-
          --health-cmd "pg_isready -U timetrack" --health-interval 5s --health-retries 5
    env: { RAILS_ENV: test, DATABASE_HOST: localhost, POSTGRES_USER: timetrack, ... }
    defaults: { run: { working-directory: backend } }
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { working-directory: backend, bundler-cache: true }
      - run: bin/rails db:test:prepare
      - run: bundle exec rspec

  backend-lint:        # rubocop + brakeman + bundler-audit
    defaults: { run: { working-directory: backend } }
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { working-directory: backend, bundler-cache: true }
      - run: bundle exec rubocop -f github
      - run: bin/brakeman --no-pager -q
      - run: bin/bundler-audit check --update

  frontend:            # tsc + eslint
    defaults: { run: { working-directory: frontend } }
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { package_json_file: frontend/package.json }   # ← モノレポの肝
      - uses: actions/setup-node@v4
        with: { node-version: 24, cache: pnpm, cache-dependency-path: frontend/pnpm-lock.yaml }
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec tsc --noEmit
      - run: pnpm lint
```

これに加えて、別ファイル `security.yml` で **gitleaks**（機密スキャン）を全 push/PR に走らせ、
`dependabot.yml` で bundler / npm / github-actions の依存更新を週次で受ける。

## ハマったこと・学び

1. **モノレポでは「アクションの作業ディレクトリ」に注意**
   `defaults.run.working-directory` は `run:` ステップにしか効かない。
   `pnpm/action-setup` はリポジトリ直下の `package.json` を見るので、
   `frontend/` にある本プロジェクトでは版を特定できず失敗した。
   → `package_json_file: frontend/package.json` を明示。
   `ruby/setup-ruby` も `working-directory: backend` を渡して Gemfile を見つけさせる。

2. **CI は `eager_load` が有効 → Zeitwerk の命名チェックに引っかかる**
   Rails の test 環境は CI 上で `eager_load = true`。ローカル（遅延ロード）では出なかった
   `NameError: uninitialized constant PublicId::Migration` が CI でだけ発生した。
   ファイル名と定数名がズレていたのが原因で、`lib/public_id_migration.rb`（`PublicIdMigration`）に揃えて解決。
   → **「ローカルで動く」と「CI で通る」は別**。`bin/rails zeitwerk:check` で事前確認できる。

3. **PostgreSQL は health check 付きサービスで待つ**
   サービスコンテナに `pg_isready` の healthcheck を付け、`db:test:prepare` 前に DB を待つ。

4. **Lint は事前にローカルで通す**
   rubocop（omakase）は trailing comma 禁止・配列内スペース必須など独自スタイル。
   先に `rubocop -A` で整え、eslint も `react-hooks/set-state-in-effect` 等を解消してから push した。

## 多層チェックの全体像

| レイヤー | ツール | 目的 |
|---|---|---|
| テスト | rspec | API の契約（正常 + 異常 + 認可） |
| Lint | rubocop / eslint + tsc | 一貫スタイル・型 |
| セキュリティ | brakeman / bundler-audit | Rails 脆弱性・既知 CVE |
| 機密スキャン | gitleaks | 鍵・トークンの誤コミット検出 |
| 依存更新 | dependabot | 定期的なアップデート |

## まとめ

- モノレポ CI は **ジョブを backend / frontend に分け**、各々で必要なチェックを回す。
- アクションの **working-directory / 設定ファイルの場所**を明示（pnpm・ruby setup）。
- **CI の eager_load** を前提に Zeitwerk 命名を揃える（`zeitwerk:check`）。
- テスト・Lint・セキュリティ・機密スキャン・依存更新を**多層**で自動化し、PR を緑前提で運用する。

関連記事:
[05. Docker 開発環境](05-docker-dev-environment.md) /
[03. API駆動開発の進め方](03-api-driven-development.md)
