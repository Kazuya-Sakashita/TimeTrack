# 動詞ベースAPIをやめて「リソース中心」に作り直した話 — 勤怠打刻のリファクタ

> TimeTrack（API駆動で作る勤怠管理システム）の開発記録。
> 構成: Next.js + Rails API + PostgreSQL。設計方針は [`docs/backend-controller-design.md`](../backend-controller-design.md)。

## 結論（PREP の P）

勤怠打刻の API を `POST /attendances/clock-in` のような**動詞ベース**から、
`POST /attendances`（作成）・`PATCH /attendances/:id`（状態変更）・`/attendances/:id/breaks`（別リソース）という
**リソース中心（RESTful）**へ作り直した。URL から「リソースと操作」が一意に読めるようになり、
OpenAPI・テスト・フロントの型が素直に対応づくようになった。

## 課題（Before）

Phase1 で打刻機能を素早く作ったとき、エンドポイントはこうなっていた。

```text
POST /attendances/clock-in     # 出勤
POST /attendances/clock-out    # 退勤
POST /attendances/break-start  # 休憩開始
POST /attendances/break-end    # 休憩終了
```

動くし分かりやすい。でも「動詞 API」は増え続ける。承認なら `/approve`、
取消なら `/cancel`、申請なら `/submit`…とリソースごとに語彙が散らばり、
コントローラのアクションも `clock_in` のような独自メソッドだらけになる。
チームや将来の自分が API を予測できなくなり、設計が崩れていく。

そこで開発ルールとして「**リソース中心で設計する／動詞アクションは原則作らない**」を定め、
先に作った勤怠 API を方針に合わせて作り直すことにした。

## 解決（After）

操作を「リソースに対する CRUD」に翻訳する。

```text
出勤      POST  /attendances                       # 作成
退勤      PATCH /attendances/:id  {"status":"finished"}   # 状態変更 = update
一覧/詳細  GET   /attendances / GET /attendances/:id
休憩開始  POST  /attendances/:attendance_id/breaks       # 別リソースの作成
休憩終了  PATCH /attendances/:attendance_id/breaks/:id   # 別リソースの更新
```

ポイントは3つ。

- **状態変更は `update` で表す**（退勤＝勤怠を `finished` に更新）
- **独立した振る舞いは別リソースに切り出す**（休憩＝`breaks`）
- **`:id` は内部連番ではなく `public_id`**（外部に内部 ID を出さない）

### ルーティング

`resources` + `only:` を基本にし、`member`/`collection` は使わない（動詞アクションの温床になるため）。

```ruby
resources :attendances, only: %i[index show create update] do
  resources :breaks, only: %i[create update]
end
```

### コントローラは薄く、状態遷移はモデルへ

ビジネスロジック（状態遷移のルール）はモデルに置き、コントローラは入出力と認可呼び出しに徹する。

```ruby
# app/controllers/attendances_controller.rb
def update
  attendance = current_user.attendances.find_by!(public_id: params[:id])
  authorize attendance
  case params[:status]
  when "finished"
    attendance.clock_out!         # ← 遷移ロジックはモデル
    render json: AttendanceSerializer.call(attendance)
  else
    render_error("unsupported_update", "サポートされていない更新です")
  end
end
```

```ruby
# app/models/attendance.rb
def clock_out!
  raise InvalidTransition.new("already_clocked_out", "本日は既に退勤打刻済みです") if finished?
  raise InvalidTransition.new("on_break", "休憩を終了してから退勤してください") if on_break?
  update!(clock_out_at: Time.current, status: :finished)
end
```

不正な遷移は `InvalidTransition`（独自エラー）を投げ、`ApplicationController` でまとめて 422 に変換する。
「未出勤の勤怠を退勤する」は、存在しないリソースへの操作として `find_by!` が `RecordNotFound` → **404** で自然に表現できる（動詞時代は 422 で表していた）。

### OpenAPI（抜粋）

仕様を先に直し、それから実装する（API駆動）。退勤は状態を送る形にした。

```yaml
/attendances/{id}:
  patch:
    summary: 勤怠の更新（退勤）
    requestBody:
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/AttendanceUpdateRequest"   # { status: finished }
    responses:
      "200": { description: 更新成功 }
      "404": { description: 見つからない }
      "422": { description: 不正な状態遷移 }
```

### テスト（Request Spec）

契約が守られているかを Request Spec で担保する。

```ruby
it "200 で退勤済み・勤務時間を返す" do
  attendance = create(:attendance, user: user, clock_in_at: 8.hours.ago, status: :working)
  patch "/attendances/#{attendance.public_id}", params: { status: "finished" }, headers: auth_headers

  expect(response).to have_http_status(:ok)
  body = JSON.parse(response.body)
  expect(body["status"]).to eq("finished")
  expect(body["workMinutes"]).to be_within(2).of(480)
end
```

## ハマったこと・学び

1. **Pundit はアクション名から権限メソッドを推測する**
   `authorize attendance` を `update` アクションで呼ぶと `AttendancePolicy#clock_out?` ではなく
   `#update?` を探す…のではなく、アクション名に対応するメソッドを探す。意図する権限名は明示するのが安全。
   ```ruby
   authorize attendance, :create?   # アクション名に引っ張られない
   ```

2. **Ruby 3 のキーワード引数**
   `JsonWebToken.encode(user_id: x)` は「キーワード引数」と解釈され、位置引数 `payload` が埋まらず
   `ArgumentError`。ハッシュを明示する。
   ```ruby
   JsonWebToken.encode({ user_id: user.id })
   ```

3. **CI（eager_load 有効）で Zeitwerk の命名チェックに引っかかる**
   ローカル（development）は遅延ロードなので気づかなかったが、CI は `eager_load = true`。
   `lib/public_id/migration.rb` が `PublicId::Migration` を期待されてしまい `NameError`。
   ファイル名を定数に合わせて `lib/public_id_migration.rb`（`PublicIdMigration`）に改名して解決。
   → **「動く」と「CI で通る」は別**。eager load 前提で命名を揃える。

4. **破壊的変更は設計→実装の順で、ドキュメントも同時に**
   先に方針 (`backend-controller-design.md`) と OpenAPI を直し、実装・テスト・フロントを追従させた。
   実装だけ変えてドキュメントが古いまま、を避けられた。

## まとめ

- 動詞 API は短期的には楽だが、増えるほど設計が崩れる。**リソース中心**にすると一貫性と予測可能性が上がる。
- 状態変更は `update`、独立した振る舞いは**別リソース**に切り出す。`member`/`collection` は安易に使わない。
- ロジックはモデル、コントローラは薄く。不正遷移は専用エラー→422、存在しないリソースは 404。
- リファクタは「設計ドキュメント → OpenAPI → 実装 → テスト → フロント」の順で、ドキュメントを置き去りにしない。

次回は「Pundit でロール別の認可（申請の承認フロー）をどう設計したか」を書く予定。
