# Pundit でロール別の認可を設計する — 勤怠修正申請の承認フロー

> TimeTrack（API駆動で作る勤怠管理システム）の開発記録。
> 前提: 認証は JWT、認可は Pundit。設計方針は [`docs/security-policy.md`](../security-policy.md) / [`docs/backend-controller-design.md`](../backend-controller-design.md)。

## 結論（PREP の P）

「従業員が打刻の修正を申請し、管理者が承認/却下する」フローを、**認証(401)と認可(403)を分離**し、
**認可ロジックは Pundit の Policy に集約**して実装した。
ポイントは3つ:

- 承認/却下は動詞 API（`/approve`）ではなく **`PATCH /:id { status }`**（状態更新）で表す
- 「誰が何を見られるか」は **Policy::Scope**、「誰が操作できるか」は **`update?`/`destroy?`** に分ける
- **申請者は自分の申請を承認できない**（`reviewer? && !own?`）など、業務ルールを Policy に明記する

## 課題

修正申請にはロールごとに違う見え方・操作が要る。

- 従業員: 自分の申請だけ作成・閲覧・取消できる
- 管理者(manager/admin): すべての申請を閲覧し、承認/却下できる
- ただし**自分が出した申請を自分で承認するのは禁止**

これをコントローラの `if user.admin?` で書き散らすと、すぐに見通しが悪くなり抜け漏れも出る。
認可は一箇所（Policy）に集約したい。

## 解決

### モデルとロール

`User` は role enum（`employee` / `manager` / `admin`）を持つ。
申請 `AttendanceChangeRequest` は申請者 `user`、対象 `attendance`、`status`(pending/approved/rejected)、`reviewer` を持つ。

### Policy に「見える範囲」と「操作」を集約

```ruby
# app/policies/attendance_change_request_policy.rb
class AttendanceChangeRequestPolicy < ApplicationPolicy
  # 一覧で「見える範囲」: 従業員は自分の申請、承認者は全件
  class Scope < ApplicationPolicy::Scope
    def resolve
      reviewer? ? scope.all : scope.where(user_id: user.id)
    end

    private

    def reviewer? = user.manager? || user.admin?
  end

  def create?  = own?                    # 自分の勤怠にだけ申請できる
  def show?    = own? || reviewer?       # 自分の申請、または承認者は閲覧可
  def update?  = reviewer? && !own?      # 承認/却下は承認者のみ・自分の申請は不可
  def destroy? = own? && record.pending? # 取消は申請者本人・申請中のみ

  private

  def own? = user.present? && record.user_id == user.id
  def reviewer? = user.present? && (user.manager? || user.admin?)
end
```

`update? = reviewer? && !own?` の `&& !own?` が、
「manager が自分の申請を自分で承認する」を1行で禁止している。業務ルールがコードに見える。

### コントローラは Policy を呼ぶだけ

```ruby
# 一覧: policy_scope でロール別に絞り込み
def index
  requests = policy_scope(AttendanceChangeRequest).order(created_at: :desc)
  requests = requests.where(status: params[:status]) if AttendanceChangeRequest.statuses.key?(params[:status])
  render json: requests.map { |r| AttendanceChangeRequestSerializer.call(r) }
end

# 承認/却下: 状態更新として表現
def update
  change_request = AttendanceChangeRequest.find_by!(public_id: params[:id])
  authorize change_request                 # ← update? が呼ばれる
  case params[:status]
  when "approved" then change_request.approve!(reviewer: current_user, comment: params[:comment])
  when "rejected" then change_request.reject!(reviewer: current_user, comment: params[:comment])
  else return render_error("unsupported_update", "status は approved / rejected のいずれかです")
  end
  render json: AttendanceChangeRequestSerializer.call(change_request)
end
```

`pundit_user` に `current_user` を渡しておくのを忘れずに（`ApplicationController`）。

```ruby
def pundit_user = current_user
rescue_from Pundit::NotAuthorizedError, with: :render_forbidden   # → 403
```

### 承認は「勤怠への反映」までを1トランザクションで

承認ロジックはコントローラではなくモデルに置く。

```ruby
# app/models/attendance_change_request.rb
def approve!(reviewer:, comment: nil)
  ensure_pending!                              # 申請中以外は InvalidTransition → 422
  transaction do
    apply_to_attendance!                       # proposed 時刻を対象 Attendance に反映
    update!(status: :approved, reviewer:, reviewed_at: Time.current, review_comment: comment)
  end
end
```

### テスト（認可は必ず異常系も書く）

Request Spec と Policy Spec の両方で、ロールごとの可否を検証する。

```ruby
it "申請者本人（従業員）は承認できず 403" do
  patch ".../#{change_request.public_id}", params: { status: "approved" }, headers: employee_headers
  expect(response).to have_http_status(:forbidden)
end

it "manager でも自分の申請は承認できず 403" do
  own = create(:attendance_change_request, user: manager)
  patch ".../#{own.public_id}", params: { status: "approved" }, headers: manager_headers
  expect(response).to have_http_status(:forbidden)
end
```

```ruby
# Policy Spec: Scope がロールで切り替わる
it "従業員は自分の申請のみ" do
  mine = create(:attendance_change_request, user: applicant)
  create(:attendance_change_request, user: other)
  resolved = AttendanceChangeRequestPolicy::Scope.new(applicant, AttendanceChangeRequest.all).resolve
  expect(resolved).to contain_exactly(mine)
end
```

## ハマったこと・学び

1. **認証(401)と認可(403)は別物**
   トークンが無い/不正＝401（Authenticatable concern）、ログイン済みだが権限が無い＝403（Pundit）。
   ステータスコードを混ぜない。

2. **「見える範囲」は Scope、「操作の可否」はメソッド**
   一覧の絞り込みを `index?` に書くのではなく `Scope#resolve` に置く。役割が分かれてテストしやすい。

3. **業務ルールこそ Policy に書く**
   「自分の申請は自分で承認できない」は仕様。`update? = reviewer? && !own?` のように
   Policy に1行で残すと、仕様変更にも強い。

4. **承認の副作用（勤怠反映）はモデル/トランザクションで**
   コントローラに副作用を書かない。`approve!` が「状態更新＋勤怠反映」を原子的に行う。

## まとめ

- 認可は Pundit に集約し、コントローラは `authorize` / `policy_scope` を呼ぶだけにする。
- 「見える範囲＝Scope」「操作＝`update?`/`destroy?`」と分けると、ロール別の仕様が読めるコードになる。
- 承認/却下は動詞 API ではなく状態更新（`PATCH :id { status }`）で表し、副作用はモデルのトランザクションに閉じ込める。
- 認可は**異常系（403）まで必ずテスト**する。

関連記事: [01. 動詞ベースAPIをやめて「リソース中心」に作り直した話](01-verb-api-to-resource-centric.md)
