# データベース方針

## 基本

- RDB は PostgreSQL。
- 主キーは連番 `id`（内部利用のみ）。
- 外部公開には `public_id` を使う。

## public_id ルール（重要）

### なぜ使うか（設計意図）

- 連番 ID を公開すると、件数推測・順次アクセス・情報漏えいにつながる。
- URL / API に意味のない一意 ID を使うことで内部構造を隠せる。

### ルール

- すべての外部公開テーブルに `public_id` カラムを持たせる。
- prefix でリソース種別を表す。
  - user → `usr_`
  - attendance → `att_`
  - correction request → `cor_`（例。確定時に追記）
- `public_id` には **一意インデックス** を付ける。
- 生成は衝突しにくいランダム文字列（例: nanoid / SecureRandom 系）。
- API・URL・レスポンスでは `id` を返さず `public_id` を返す。

### 例

```
❌ /users/1
✅ /users/usr_8Fk2qZ
```

## テーブル設計の指針

- マイグレーションは 1 目的 1 ファイル。
- 外部キー・NOT NULL・一意制約を適切に付ける。
- 時刻は UTC 保存を基本とし、表示側で変換する。
- N+1 を避ける設計・クエリ（`includes` / `preload`）。

## 想定エンティティ（暫定・実装時に確定）

- User（従業員 / 管理者、role を持つ）
- Attendance（出勤・退勤・休憩の打刻）
- CorrectionRequest（修正申請、status を持つ）

> 実際のスキーマは OpenAPI と合わせて実装フェーズで確定する。
