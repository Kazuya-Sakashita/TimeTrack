# API駆動開発の進め方 — OpenAPI を起点に1機能を縦に通す

> TimeTrack（勤怠管理システム）の開発記録。
> 構成: Next.js + Rails API + PostgreSQL。方針は [`docs/api-driven-development.md`](../api-driven-development.md)。

## 結論（PREP の P）

機能を「フロントから作る／バックから作る」ではなく、**OpenAPI（API の契約）を先に確定**し、
そこから Rails 実装 → Request Spec → Next.js の順に**1機能ずつ縦に通す**。
契約が中心にあることで、フロントとバックが食い違わず、テスト・型・モックが仕様から導ける。

## 課題

個人開発でフロントとバックを同時に書くと、こうなりがち:

- 「この API のレスポンス、結局どの形だっけ？」が実装を読まないと分からない
- フロントを直すとバックも直す、を往復して仕様が曖昧になる
- 後から「契約」を思い出せず、テストも場当たりになる

TimeTrack では **OpenAPI を唯一の仕様書**と決め、実装より先に契約を書くことにした。

## 解決：開発フロー

1機能（=1スライス=1PR=1記事）を、必ずこの順で縦に通す。

```text
1. OpenAPI 定義     # パス / リクエスト / レスポンス / ステータス / エラー
   ↓
2. レビュー         # 命名・粒度・public_id・認可要件
   ↓
3. Rails 実装       # Controller は薄く、ロジックは Model/Service
   ↓
4. Request Spec     # 契約どおりかを検証（正常 + 異常 + 認可）
   ↓
5. Next.js 実装     # 契約に対応する型で API を呼ぶ
   ↓
6. 動作確認         # ブラウザ / curl で疎通
```

### 1. まず契約を書く（OpenAPI）

例として「出勤打刻＝勤怠の作成」。先にこう決める。

```yaml
# openapi/openapi.yaml（抜粋）
/attendances:
  post:
    summary: 出勤打刻（勤怠の作成）
    responses:
      "201": { description: 作成成功, content: { application/json: { schema: { $ref: "#/components/schemas/Attendance" } } } }
      "401": { description: 未認証 }
      "422": { description: 既に本日出勤済み }
components:
  schemas:
    Attendance:
      type: object
      required: [id, workDate, status]
      properties:
        id:        { type: string, example: att_a1B2c3D4e5F6 }  # public_id（内部IDは出さない）
        workDate:  { type: string, format: date }
        status:    { type: string, enum: [working, on_break, finished] }
```

ここで「**ID は public_id**」「**エラーは共通 Error スキーマ**」「**認証が要るか**」まで決めておくのが効く。

### 2〜3. レビューして Rails 実装

契約に沿って実装する。コントローラは薄く、状態やロジックはモデルへ。

```ruby
def create
  return render_error("already_clocked_in", "本日は既に出勤打刻済みです") if current_user.attendances.exists?(work_date: Date.current)
  attendance = current_user.attendances.build(work_date: Date.current, clock_in_at: Time.current, status: :working)
  authorize attendance
  attendance.save!
  render json: AttendanceSerializer.call(attendance), status: :created
end
```

レスポンス整形は Serializer に通し、**内部 id を出さず public_id を `id` として返す**。

```ruby
class AttendanceSerializer
  def self.call(a)
    { id: a.public_id, workDate: a.work_date.iso8601, status: a.status, workMinutes: a.worked_minutes, ... }
  end
end
```

### 4. Request Spec で契約を担保

「契約どおりか」をリクエストスペックで検証する。正常系だけでなく**異常系・認可**も必ず。

```ruby
it "201 で出勤記録を作成する" do
  post "/attendances", headers: auth_headers
  expect(response).to have_http_status(:created)
  expect(JSON.parse(response.body)["id"]).to start_with("att_")   # public_id が返る
end

it "本日2回目は 422" do
  create(:attendance, user: user, work_date: Date.current)
  post "/attendances", headers: auth_headers
  expect(response).to have_http_status(:unprocessable_entity)
end

it "未認証は 401" do
  post "/attendances"
  expect(response).to have_http_status(:unauthorized)
end
```

### 5. Next.js は契約に対応する型で呼ぶ

OpenAPI の `Attendance` に対応する型を用意し、`any` を使わない。

```ts
export type Attendance = {
  id: string;
  workDate: string;
  status: "working" | "on_break" | "finished";
  workMinutes: number | null;
  // ...
};

export function clockIn(token: string): Promise<Attendance> {
  return attendanceRequest(token, "POST", "/attendances", "出勤打刻に失敗しました");
}
```

フロントは「契約上どんな形か」を型で知っているので、レスポンスの形を実装から推測しなくて済む。

## 「完了の定義」を決めておく

API 実装は、次が揃って初めて「完了」とした。曖昧さを排除できる。

1. OpenAPI に定義がある
2. Rails 実装がある
3. Request Spec が通る（正常 + 異常 + 認可）
4. 内部 id が漏れていない（public_id）
5. フロントが契約どおりに動く

## ハマったこと・学び

1. **契約とコードがズレたら「契約を正」にする**
   迷ったら OpenAPI に寄せる。仕様を変えたいときも、まず OpenAPI を直してから実装する。

2. **異常系を先に契約へ書くと実装が楽**
   401 / 403 / 404 / 422 をどの場面で返すか先に決めておくと、コントローラの分岐が自然に決まる。

3. **縦に薄く通すと手戻りが少ない**
   「バックを全部作ってからフロント」より、1エンドポイントを契約→実装→テスト→UI まで通す方が、
   早く動いて誤りにも早く気づける。

## まとめ

- **OpenAPI を唯一の仕様書**にして、実装より先に契約を確定する。
- 1機能を `契約 → 実装 → Request Spec → フロント` の順で縦に通す。
- public_id・共通エラー・認可要件を契約段階で決めておく。
- 「完了の定義」を明文化し、テスト（特に異常系・認可）で契約を担保する。

関連記事:
[01. 動詞API→リソース中心](01-verb-api-to-resource-centric.md) /
[02. Pundit ロール別認可](02-pundit-approval-flow.md)
