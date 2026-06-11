# TimeTrack
# TimeTrack

> API駆動開発で構築する勤怠管理システム

TimeTrack は、従業員の出退勤管理を行うための Web アプリケーションです。

本プロジェクトは単なる勤怠管理システムではなく、**OpenAPI を中心とした API 駆動開発（API-Driven Development）** を実践しながら、Next.js と Ruby on Rails を組み合わせたモダンなフルスタック開発を学ぶことを目的としています。

---

## 🎯 プロジェクトの目的

多くの個人開発では、フロントエンドとバックエンドを同時に実装しながら仕様が曖昧になりがちです。

TimeTrack では以下の考え方を採用しています。

* OpenAPI を唯一の仕様書とする
* API を先に設計する
* フロントエンドとバックエンドを分離する
* 型安全な開発を実現する
* 実務レベルの認証・認可を実装する
* テストを前提とした開発を行う

---

## ✨ 主な機能

### 従業員機能

* ログイン
* 出勤打刻
* 退勤打刻
* 休憩開始
* 休憩終了
* 勤怠履歴確認
* 月次勤怠確認
* 打刻修正申請

### 管理者機能

* 従業員一覧
* 勤怠一覧
* 修正申請承認
* 修正申請却下
* 月次勤怠確認
* ダッシュボード

### 将来実装予定

* 有給申請
* Slack通知
* AI勤怠分析
* CSV出力
* 勤怠レポート生成
* 勤怠異常検知

---

## 🏗️ システム構成

```
┌──────────────┐
│   Next.js    │
│  Frontend    │
└──────┬───────┘
│
│ OpenAPI
│
┌──────▼───────┐
│ Ruby on Rails│
│     API      │
└──────┬───────┘
│
┌──────▼───────┐
│ PostgreSQL   │
└──────────────┘
```

---

## 🚀 技術スタック

### Frontend

* Next.js
* TypeScript
* React
* Tailwind CSS
* shadcn/ui
* React Hook Form
* Zod
* TanStack Query

### Backend

* Ruby on Rails (API Mode)
* PostgreSQL
* RSpec
* Pundit
* JWT Authentication

### Development

* OpenAPI
* Docker
* GitHub Actions
* ESLint
* Prettier

---

## 📚 API駆動開発

本プロジェクトでは OpenAPI を中心に開発を進めます。

```
openapi/
└── openapi.yaml
```

開発フロー

```

1. OpenAPI設計
   ↓
2. APIレビュー
   ↓
3. Rails実装
   ↓
4. RequestSpec実装
   ↓
5. Next.js実装
   ↓
6. E2E確認
   ```

### API / Controller 設計方針（リソース中心）

API は**リソース中心（RESTful）**で設計します。動詞ベースの独自アクション（approve / clock_in など）は避け、標準アクションで表現します。

```text
作成        POST   /resources
状態変更    PATCH  /resources/:id
別の振る舞い 別リソースに切り出す（例: 休憩 = /attendances/:id/breaks）
```

詳細・判断基準は [`docs/backend-controller-design.md`](docs/backend-controller-design.md) を参照。

---

## 🔒 セキュリティ

### Public ID

内部IDを公開しません。

❌

```
/users/1
/users/2
/users/3
```

✅

```
/users/usr_xxxxxxxxx
/users/usr_xxxxxxxxx
/users/usr_xxxxxxxxx
```

### 認可

Pundit を利用して権限制御を行います。

* 従業員
* 管理者

ロールごとにアクセス制御を実施します。

---

## 🧪 テスト戦略

### Backend

* Model Spec
* Request Spec
* Policy Spec

### Frontend

* Component Test
* Integration Test

### API

OpenAPI と RequestSpec を利用して契約テストを実施します。

---

## 📂 ディレクトリ構成

```
.
├── frontend
│   ├── src
│   └── public
│
├── backend
│   ├── app
│   ├── spec
│   └── config
│
├── openapi
│   └── openapi.yaml
│
├── docs
│
└── docker-compose.yml
```

---

## 📝 技術ブログ

このプロジェクトでは開発内容を技術ブログとして継続的に発信します。

### 執筆予定

* API駆動開発とは
* OpenAPIの設計方法
* Next.js × Rails構成
* Public ID設計
* Punditによる認可
* Request Spec実践
* N+1問題と対策
* 勤怠システムのDB設計
* AI活用による開発効率化

---

## 🎯 今後のロードマップ

### Phase1

* 認証
* 出勤
* 退勤
* 勤怠一覧

### Phase2

* 修正申請
* 承認フロー

### Phase3

* 月次集計
* レポート

### Phase4

* AI分析
* Slack連携

---

## 👨‍💻 Author

Kazuya Sakashita

GitHub:
https://github.com/Kazuya-Sakashita

---

## 📄 License

MIT License
