# Phase1 / Slice 1 — 認証 詳細計画

> `framework-based-planning.md` に従い Vertical Slice + 依存順分解で立案。
> 親計画: `phase1.md`（Slice 1）。対応 Issue: #3

## ゴール

ログインして JWT を取得し、認証済みで自分の情報（/me）を取得できる。
ログイン画面（V0 リファクタ）から実際にログインできる。

## 設計判断

| 項目 | 選定 | 理由 |
|---|---|---|
| パスワード | bcrypt + `has_secure_password` | 標準・安全 |
| 認証方式 | JWT (Bearer) stateless | フロント/バック分離に適合 |
| logout | クライアントでトークン破棄 + サーバ 204 | スライスを小さく保つ。denylist は将来拡張 |
| role | employee / manager / admin | V0 の UI ロールに合わせる |
| 認可 | Pundit 下地のみ（本格運用は後続スライス） | 認証と認可を分離 |

## タスク（依存順）

- [x] 1-A OpenAPI: `/auth/login`(POST) `/auth/logout`(DELETE) `/me`(GET) + User/LoginRequest/AuthToken スキーマ
- [x] 1-B User モデル + migration（public_id, email一意, password_digest, name, role enum）
- [x] 1-C JWT サービス（encode/decode、`JWT_SECRET_KEY`、exp 24h）
- [x] 1-D 認証 concern Authenticatable（Bearer 検証 → current_user、失敗 401）
- [x] 1-E コントローラ（Auth::Sessions#create/#destroy, Me#show）+ ルート
- [x] 1-F Pundit 下地（ApplicationPolicy, pundit_user = current_user, 403 rescue）
- [x] 1-G Request Spec（login 正常/不正/422、me 認証/未認証401/改ざん、logout 204）16 examples 緑
- [x] 1-H seeds（admin / manager / employee、password="password"）
- [x] 1-I frontend: ログイン画面（V0 トークン移植 + リファクタ）→ token 保存 → /dashboard で /me 表示

## 実装メモ（記事素材）

- public_id 採番は presence バリデーションより先に走らせる必要があり `before_validation on: :create` に修正。
- Ruby 3 の引数仕様: `JsonWebToken.encode(user_id: x)` はキーワード扱いになり位置引数 payload が埋まらず ArgumentError。呼び出しは `encode({ ... })` と明示。
- logout はステートレス JWT のためサーバ 204、クライアントが localStorage のトークンを破棄。
- デザイン基準の段階的取り込み: V0 の globals.css カラートークン（OKLCH, primary #2563EB, light/dark）を frontend に移植し、`bg-primary` 等のセマンティックユーティリティを有効化。shadcn コンポーネントの本格導入は後続スライスで段階的に。
- Docker: フロントの新規依存（lucide-react）は anonymous volume が旧 node_modules を覆うため `--renew-anon-volumes` で再作成が必要。

## 完了の定義（DoD）

1. OpenAPI に login/logout/me が定義済み
2. Request Spec 緑（正常 + 異常 + 認可: 401）
3. レスポンスは public_id（内部 id 非公開）
4. ログイン画面から実際にログインでき、/me が表示される
5. 設計意図・つまずきメモを残す
