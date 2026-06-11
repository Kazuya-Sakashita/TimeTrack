# 内部IDを公開しない — public_id でリソースIDを設計する

> TimeTrack（勤怠管理システム）の開発記録。
> 方針は [`docs/database-policy.md`](../database-policy.md) / [`docs/security-policy.md`](../security-policy.md)。

## 結論（PREP の P）

URL や API レスポンスに DB の連番 `id`（`1, 2, 3...`）を出さず、
**prefix 付きのランダムな `public_id`（例 `usr_a1B2c3D4e5F6`）**を外部公開用 ID にした。
concern（`HasPublicId`）とマイグレーションヘルパ（`add_public_id`）で全モデルに一貫して適用している。

## 課題：連番 ID を公開する危うさ

```text
GET /users/1
GET /users/2
GET /users/3
```

連番 ID をそのまま公開すると、

- **件数や規模が推測できる**（`/attendances/1024` を見れば総数の目安がつく）
- **順次アクセスで列挙されやすい**（1, 2, 3... と総当たり）
- 認可漏れがあると**他人のリソースに辿り着きやすい**

勤怠・申請のような業務データでは避けたい。そこで**内部 id は外に出さない**方針にした。

## 解決：public_id

外部公開には prefix 付きのランダム ID を使う。

```text
❌ /attendances/1            ✅ /attendances/att_8Fk2qZ9xWp3r
❌ /users/2                  ✅ /users/usr_a1B2c3D4e5F6
```

prefix でリソース種別が一目で分かる（`usr_` / `att_` / `acr_`（修正申請）/ `brk_`（休憩））。

### 生成ロジック（純粋関数）

DB 非依存でテストしやすいよう、生成は純粋なモジュールに切り出す。

```ruby
# app/models/concerns/public_id.rb
module PublicId
  RANDOM_LENGTH = 12
  module_function

  def generate(prefix:, length: RANDOM_LENGTH)
    raise ArgumentError, "prefix is required" if prefix.blank?
    "#{prefix}_#{SecureRandom.alphanumeric(length)}"
  end
end
```

### モデルに持たせる concern

```ruby
# app/models/concerns/has_public_id.rb
module HasPublicId
  extend ActiveSupport::Concern

  included do
    # presence バリデーションより先に採番するため before_validation を使う
    before_validation :assign_public_id, on: :create
    validates :public_id, presence: true, uniqueness: true
  end

  class_methods do
    def has_public_id_prefix(prefix) = @public_id_prefix = prefix
    def generate_public_id = PublicId.generate(prefix: @public_id_prefix || raise("prefix 未設定"))
  end

  def to_param = public_id   # ルーティングで内部 id ではなく public_id を使う

  private

  def assign_public_id = self.public_id ||= self.class.generate_public_id
end
```

使う側はこれだけ。

```ruby
class User < ApplicationRecord
  include HasPublicId
  has_public_id_prefix "usr"
end
```

### マイグレーションヘルパ

NOT NULL + 一意インデックスを毎回そろえる。

```ruby
# lib/public_id_migration.rb （ActiveRecord::Migration に include）
module PublicIdMigration
  def add_public_id(t)
    if t.respond_to?(:string)   # create_table のブロック内
      t.string :public_id, null: false
      t.index  :public_id, unique: true
    else
      add_column t, :public_id, :string, null: false
      add_index  t, :public_id, unique: true
    end
  end
end
```

```ruby
create_table :attendances do |t|
  add_public_id t
  # ...
end
```

### レスポンスでは public_id を `id` として返す

Serializer で内部 id を出さず、`public_id` を `id` という名前で返す。
フロントは内部 id を一切知らない前提で動く。

```ruby
class UserSerializer
  def self.call(user)
    { id: user.public_id, email: user.email, name: user.name, role: user.role }
  end
end
```

### コントローラは public_id で引く

```ruby
def show
  attendance = current_user.attendances.find_by!(public_id: params[:id])  # 内部 id では引かない
  authorize attendance
  render json: AttendanceSerializer.call(attendance)
end
```

`find_by!` なので、存在しない（または自分のものでない）public_id は `RecordNotFound` → **404** になる。

### テスト

```ruby
it "内部 id を漏らさず public_id を id として返す" do
  post "/auth/login", params: { email: "admin@example.com", password: "password" }
  body = JSON.parse(response.body)
  expect(body["user"]["id"]).to start_with("usr_")
  expect(body["user"]).not_to have_key("password_digest")
end

it "呼び出しごとに異なる値を返す（衝突しにくい）" do
  ids = Array.new(1000) { PublicId.generate(prefix: "usr") }
  expect(ids.uniq.size).to eq(1000)
end
```

## ハマったこと・学び

1. **採番タイミングは `before_validation`**
   `before_create` で採番すると、presence バリデーション（`valid?` 時）の方が先に走って
   「public_id が空」で落ちる。`before_validation on: :create` にして解決。

2. **生成ロジックと concern を分ける**
   生成（`PublicId.generate`）は純粋関数にして DB なしで単体テスト。
   モデルへの組み込み（`HasPublicId`）は別。テストしやすく責務も明確。

3. **public_id は「難読化」であって「認可」ではない**
   推測されにくくなるだけで、認可の代わりにはならない。
   必ず Pundit などで「そのユーザーが触れてよいか」を別途チェックする。

4. **`to_param` を public_id にするとルーティングが自然**
   リンク生成も `params[:id]` も public_id に揃い、内部 id が URL に漏れない。

## まとめ

- 外部公開 ID は連番ではなく **prefix 付きランダムの public_id**。種別が読めて列挙されにくい。
- 生成（純粋関数）＋ concern（モデル組み込み）＋ マイグレーションヘルパ で**一貫適用**。
- レスポンス・URL・`to_param` すべてを public_id に統一し、内部 id を外に出さない。
- ただし public_id は難読化にすぎず、**認可は別途必須**。

関連記事:
[01. 動詞API→リソース中心](01-verb-api-to-resource-centric.md) /
[02. Pundit ロール別認可](02-pundit-approval-flow.md) /
[03. API駆動開発の進め方](03-api-driven-development.md)
