# Backend Controller Design

Rails の Controller / API を「リソース中心（RESTful）」で設計するための方針。
動詞ベースの独自アクションを避け、設計とドキュメントを実装と同期させる。

## 基本方針

- Controller は **Rails 標準の RESTful アクション**（index / show / create / update / destroy）を優先する。
- **独自アクションは原則追加しない**（`clock_in` のような動詞メソッドを作らない）。
- **状態変更は update で表現する**（例: 退勤＝勤怠レコードの状態更新）。
- **振る舞いは別リソースとして切り出す**（例: 休憩＝breaks リソース）。
- **Controller にビジネスロジックを置かない**（Model / Service に寄せる。Controller は入出力と認可呼び出しに徹する）。

## RESTful Action

| 操作 | アクション | HTTP |
|---|---|---|
| 一覧 | index | GET /resources |
| 詳細 | show | GET /resources/:id |
| 作成 | create | POST /resources |
| 更新（状態変更含む） | update | PATCH /resources/:id |
| 削除 | destroy | DELETE /resources/:id |

ID は内部連番ではなく **public_id** を使う（`to_param` で公開）。

## 独自アクションを避ける理由

- URL から「リソースと操作」が一意に読め、API の一貫性・予測可能性が上がる。
- 動詞 API（approve / reject / submit / leave / join / clock_in …）は際限なく増え、設計が崩れる。
- OpenAPI・テスト・フロントの型が素直に対応づき、保守しやすい。

### アンチパターン → リソース中心への置き換え例

```text
POST /attendances/clock-in     → POST  /attendances                  (create)
POST /attendances/clock-out    → PATCH /attendances/:id              (状態変更=update)
POST /attendances/break-start  → POST  /attendances/:id/breaks       (別リソース create)
POST /attendances/break-end    → PATCH /attendances/:id/breaks/:id   (別リソース update)

POST /requests/:id/approve     → PATCH /attendance_change_requests/:id
POST /groups/:id/join          → POST  /memberships
POST /groups/:id/leave         → DELETE /memberships/:id
POST /reports/:id/finalize     → PATCH /monthly_reports/:id
```

## 状態変更の扱い

- 状態遷移は「対象リソースの update」で表現する（例: `PATCH /attendances/:id { "status": "finished" }`）。
- 不正な遷移はバリデーション / ガードで弾き、`422` を返す。
- 認可は Pundit の `update?` に集約する。

## 別リソース化の判断基準

次のいずれかに当てはまる振る舞いは、独自アクションではなく別リソースに切り出す。

- それ自体がライフサイクル（開始・終了 / 作成・取消）を持つ（例: 休憩、申請、メンバーシップ）。
- 0..N 個発生しうる（親に複数ぶら下がる）。
- 監査・履歴として独立して参照したい。

## Controller の責務

- パラメータの受け取りと整形
- 認可呼び出し（`authorize` / `policy_scope`）
- Model / Service の呼び出し
- レスポンス（Serializer）の返却

ビジネスロジック・複雑な分岐は Model / Service に置く。

## Routes 設計ルール

- `resources` を基本とし、`only:` で公開アクションを限定する。
- **`member do` / `collection do` を安易に使わない**（動詞アクションの温床になる）。
- ネストは1段まで（`resources :attendances do resources :breaks end`）。

```ruby
resources :attendances, only: %i[index show create update] do
  resources :breaks, only: %i[create update]
end
resources :attendance_change_requests, only: %i[index show create update]
resources :memberships, only: %i[create destroy]
resources :monthly_reports, only: %i[index show update]
```

## 新規 API 追加時の検討順

1. 既存の REST アクションで表現できるか
2. 別リソースとして切り出せるか
3. 状態変更として update で表現できるか
4. それでも難しい場合のみ、独自アクションを検討する（理由を PR / 設計に明記）

## レビュー観点

- [ ] 動詞ベースの独自アクションになっていないか
- [ ] 状態変更が update で表現されているか
- [ ] 振る舞いが適切に別リソース化されているか
- [ ] `member` / `collection` を不要に使っていないか
- [ ] Controller が薄いか（ロジックが Model / Service にあるか）
- [ ] URL / レスポンスが public_id か
- [ ] OpenAPI・README・docs が実装と同期しているか

## 現状と技術的負債

Phase1 で先行実装した勤怠打刻 API は動詞ベースで、本方針に **未準拠**（要リファクタ）。

- `POST /attendances/clock-in` / `clock-out` / `break-start` / `break-end`

→ リソース中心へ移行する計画: `docs/plans/controller-refactor.md`
