# セキュリティ方針

## 認証と認可を分ける

- **認証 (Authentication)** = 「誰か」を確認する → JWT
- **認可 (Authorization)** = 「何をしてよいか」を制御する → Pundit

この 2 つを混同せず、責務を分けて実装する（設計意図: 役割が混ざると
バグと脆弱性の温床になり、説明も難しくなるため）。

## 認証 (JWT)

- ログイン成功時にトークンを発行する。
- リクエストは `Authorization: Bearer <token>` で認証する。
- トークンには最小限の情報のみ含める（内部 ID を含めない／public_id を使う）。
- 秘密鍵は環境変数で管理し、コードに書かない。
- 失敗時は `401 Unauthorized`。

## 認可 (Pundit)

- ロールは最低限 `employee` と `admin`。
- 認可ロジックは **Policy クラスに集約** する。
- Controller では `authorize record` を呼ぶだけにする。
- View / フロントに認可ロジックを散らさない。
- 権限なしは `403 Forbidden`。

### 例（方針イメージ）

- 従業員は **自分の** 勤怠のみ閲覧・修正申請できる。
- 管理者は全従業員の勤怠を閲覧でき、修正申請を承認・却下できる。

## その他

- 内部 ID を外部に出さない（→ `database-policy.md` の public_id）。
- パスワードはハッシュ化して保存する（平文保存禁止）。
- エラーメッセージで内部情報を過剰に返さない。
- CORS は許可するオリジンを明示的に設定する。

## ステータスコードの使い分け

| 状況 | コード |
|------|--------|
| 未認証 | 401 |
| 認可なし | 403 |
| リソースなし | 404 |
| バリデーション失敗 | 422 |

## 機密情報の取り扱いと自動防御

- 秘密情報は `.env`（git 管理外）で管理し、サンプルは `.env.example` に置く。
- `.gitignore` はルートに集約（単一の管理元）。鍵・証明書・DB データ・ビルド成果物を除外。
- Rails の `master.key` は commit しない。本プロジェクトは encrypted credentials を使わず
  ENV ベースで秘密を管理するため `credentials.yml.enc` も追跡しない。
- **二段の自動検査で誤 push を防ぐ:**
  - **pre-commit フック**（`.githooks/pre-commit`）: コミット前に gitleaks でステージ差分を検査。
    - 有効化: `git config core.hooksPath .githooks`
    - 導入: `brew install gitleaks`
  - **CI**（`.github/workflows/security.yml`）: push / PR で gitleaks が履歴を走査。
- 万一 commit 済みになった場合: `git rm --cached <path>` で追跡解除し、
  **漏洩した実鍵は必ずローテーション**する（履歴削除だけでは無効化されない）。
