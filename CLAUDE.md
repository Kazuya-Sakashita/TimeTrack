# CLAUDE.md

このファイルは Claude Code がこのリポジトリで作業するときの最上位ルールです。
作業を始める前に必ず読み、迷ったらここと `docs/` を参照してください。

---

## 1. プロジェクト概要

TimeTrack は従業員の出退勤を管理する Web アプリケーションです。
単に動くアプリを作るのではなく、**API 駆動開発 (API-Driven Development)** と
**OpenAPI を仕様の中心に据えた開発** を実践することを目的とした、
ポートフォリオ兼技術ブログ用プロジェクトです。

詳細は `docs/project-overview.md` を参照。

---

## 2. 技術スタック

| 領域 | 技術 |
|------|------|
| Frontend | Next.js (App Router) / TypeScript / Tailwind CSS / shadcn/ui |
| Frontend補助 | React Hook Form / Zod / TanStack Query |
| Backend | Ruby on Rails (API Mode) |
| Database | PostgreSQL |
| API設計 | OpenAPI |
| 認証 | JWT |
| 認可 | Pundit |
| テスト | RSpec (Model / Request / Policy Spec) |
| 開発支援 | Docker / GitHub Actions / ESLint / Prettier |

---

## 3. 開発方針

- **API 駆動開発**: 実装より先に API 仕様を決める。詳細は `docs/api-driven-development.md`。
- **フロント / バック分離**: backend は Rails API、frontend は Next.js。両者は OpenAPI を介してのみ通信する。
- **OpenAPI が唯一の仕様書**: API の振る舞いは OpenAPI で定義し、実装・テスト・型はそこから導く。
- **public_id で内部 ID を隠蔽**: 連番の内部 ID を URL / レスポンスに出さない。詳細は `docs/database-policy.md`。
- **認証・認可を明確に分離**: 認証 = JWT、認可 = Pundit。詳細は `docs/security-policy.md`。
- **Request Spec を重視**: API の契約はリクエストスペックで担保する。詳細は `docs/testing-policy.md`。
- **記事化しやすい単位で進める**: 1 機能 = 1 ブログ記事を意識する。詳細は `docs/blog-strategy.md`。

---

## 4. API 駆動開発のルール

1. 新しい API は **必ず OpenAPI に定義してから** Rails を実装する。
2. 開発フロー: `OpenAPI 設計 → レビュー → Rails 実装 → Request Spec → Next.js 実装 → E2E 確認`。
3. OpenAPI とコードが食い違ったら **OpenAPI を正** とし、コードを直す。
4. エンドポイントの URL・パラメータ・レスポンス形を勝手に変えない。変更時は OpenAPI を先に更新する。

---

### API 設計方針（リソース中心）

新しい API は **リソース中心**で設計する。動詞ベース API（approve / reject / submit / join / leave / clock_in 等）は避け、次で表現する。

```text
PATCH  /attendance_change_requests/:id   # approve/reject → 状態更新
POST   /memberships                      # join → 作成
DELETE /memberships/:id                  # leave → 削除
PATCH  /monthly_reports/:id              # finalize → 状態更新
```

新規 API 追加時は次の順で検討する（詳細: `docs/backend-controller-design.md`）。

1. 既存の REST アクションで表現できるか
2. 別リソースとして切り出せるか
3. 状態変更として update で表現できるか
4. それでも難しい場合のみ独自アクションを検討する（理由を明記）

## 5. OpenAPI 更新ルール

- 仕様ファイルは `openapi/openapi.yaml`（将来作成）。
- すべての API は次を明記する: パス / メソッド / リクエスト / レスポンス / ステータスコード / エラー形式。
- ID を含むパスは内部 ID ではなく **public_id**（例: `/users/{public_id}`）。
- 破壊的変更は避け、必要なら新エンドポイントを追加する。
- スキーマには `components/schemas` を使い、重複定義を避ける。

---

## 6. Rails 実装ルール

- **API Mode** を前提とする（ビューは持たない）。
- Controller は薄く保ち、ロジックは Model / Service に寄せる。
- **リソース中心（RESTful）設計**: Controller は標準アクション（index/show/create/update/destroy）を優先し、動詞ベースの独自アクションを原則追加しない。状態変更は `update`、独立した振る舞いは別リソースに切り出す。詳細は `docs/backend-controller-design.md`。
- ルーティングは `resources` + `only:` を基本とし、`member`/`collection` を安易に使わない。
- 認可は **Pundit の Policy** に集約し、Controller では `authorize` を呼ぶだけにする。
- 外部公開するレスポンスは Serializer（または同等の整形層）を通し、内部 ID を漏らさない。
- N+1 を避ける（`includes` / `preload`）。
- マイグレーションは 1 目的 1 ファイル。`public_id` カラムを持つテーブルには一意インデックスを付ける。

---

## 7. Next.js 実装ルール

- **App Router** を使用する。
- API 通信は OpenAPI から生成 / 定義した型を使い、`any` を避ける。
- フォームは React Hook Form + Zod でバリデーションする。
- サーバー状態は TanStack Query で管理し、独自のグローバル状態を乱用しない。
- UI は shadcn/ui + Tailwind を基本とし、独自 CSS を増やしすぎない。
- API のベース URL や秘密情報は環境変数で管理し、ハードコードしない。
- **デザインは V0 生成プロトタイプ（`~/Downloads/time-track`）を基準にする**。色・余白・角丸はトークン経由で指定し、生の値をハードコードしない。詳細は `docs/design-system.md`。

---

## 8. public_id 利用ルール

- DB の主キー（連番 `id`）は **外部に一切公開しない**。
- 外部公開・URL・API レスポンスには `public_id`（例: `usr_xxxxxxxx`）を使う。
- prefix でリソース種別が分かるようにする（user→`usr_`, attendance→`att_` など）。
- フロントエンドは internal id を知らない前提で実装する。
- 詳細・設計意図は `docs/database-policy.md`。

---

## 9. 認証・認可ルール

- **認証 (Authentication)**: JWT。「誰か」を確認する。
- **認可 (Authorization)**: Pundit。「何をしてよいか」を制御する。
- ロールは最低限 `employee` と `admin` を持つ。
- 認可ロジックは Policy に集約し、Controller / View に散らさない。
- 失敗時のステータス: 未認証 = `401`、認可なし = `403`。
- 詳細は `docs/security-policy.md`。

---

## 10. テスト方針

- **Request Spec を主軸** に、API の入出力・ステータス・認可を検証する。
- Model Spec: バリデーション・スコープ・ビジネスロジック。
- Policy Spec: ロールごとの可否。
- API レスポンスが OpenAPI と一致していることを意識する（契約テスト）。
- 詳細は `docs/testing-policy.md`。

---

## 11. Git / Issue / PR 方針

- ブランチ: `main` から作業ブランチを切る（例: `feat/attendance-clock-in`）。
- 1 PR = 1 まとまった目的。巨大 PR を避ける。
- コミットメッセージは命令形で簡潔に（例: `Add clock-in endpoint to OpenAPI`）。
- Issue で「何を・なぜ」を残し、ブログ記事の素材にする。
- `main` への直接コミットは避け、PR 経由でマージする。

---

## 12. Claude Code の作業ルール

- **作業粒度を小さく保つ**。1 度に複数機能をまたいで実装しない。
- 着手前に対象の OpenAPI 定義・関連ドキュメントを確認する。
- 不明点があれば **推測で実装に入らず、質問する**。
- 既存ファイルを変更する前に内容を読む。
- 作業後は「変更ファイル一覧」と「次の一手」を報告する。
- 設計意図を簡潔に残す（後でブログ記事にできるように）。

---

## 13. 実装前に必ず確認すること

1. その作業は OpenAPI に定義済みか？ なければ先に定義する。
2. 影響範囲は backend / frontend のどちらか、両方か？
3. 認証・認可の要件は明確か？（誰がアクセスできるか）
4. public_id を使うべき箇所で内部 ID を使っていないか？
5. テスト（特に Request Spec）の方針は決まっているか？
6. 作業粒度は「1 記事」にできるくらい小さいか？
7. その API はリソース中心で表現できているか？（動詞アクションを避ける。`docs/backend-controller-design.md` の検討順）

---

## 14. やってはいけないこと

- OpenAPI を更新せずに API を実装・変更すること。
- 内部 ID（連番）を URL / レスポンスに公開すること。
- 認可ロジックを Controller やフロントに散らすこと。
- 巨大な PR / 一度に複数機能の実装。
- 動詞ベースの独自アクション / 不要な `member`・`collection` ルートを安易に追加すること（→ `docs/backend-controller-design.md`）。
- 不明点を推測で埋めて実装を進めること。
- テストなしで API を「完了」とすること。
- 秘密情報（鍵・トークン）をコードにハードコードすること。

---

## 15. Framework-Based Planning Rule（計画・判断・評価は必ずフレームワークを使用する）

TimeTrack では、Claude Code が計画・判断・評価を行う際、必ず適切なフレームワークを使用する。

これは出力を見やすくするためではなく、判断根拠を明確にし、実装の迷走を防ぐためである。

特に以下では必ずフレームワークを使う。

- 実装計画
- Issue分割
- 優先順位付け
- 技術選定
- API設計
- DB設計
- UI/UX改善
- セキュリティ評価
- テスト計画
- パフォーマンス改善
- リファクタリング
- コードレビュー
- ブログ記事構成

出力時には、使用したフレームワーク名・採用理由・評価結果・次のアクションを明記する。

詳細・推奨フレームワークは `docs/framework-based-planning.md`、
具体的な選択ルールと出力形式は `.claude/skills/framework-based-planning.md` を参照。

### 出力の基本形式

```md
## 使用したフレームワーク

- フレームワーク:
- 採用理由:

## 評価

## 計画

## 優先順位

## 次のアクション
```
