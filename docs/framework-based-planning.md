# Framework-Based Planning

TimeTrack では、計画・判断・評価を行う際に、適切なフレームワークを使用する。

> 方針名の正確な意味: 「計画・判断・評価は必ずフレームワークを使用する」。
> （見た目の整理＝「表示」のためではない。）

## 目的

- 判断根拠を明確にする
- 実装の迷走を防ぐ
- 優先順位を明確にする
- Claude Code の提案品質を安定させる
- 技術ブログで説明可能な開発プロセスを残す
- ポートフォリオとして設計力を示す

## 利用場面

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

## 推奨フレームワーク

### 実装計画
MVP / MoSCoW / RICE / Impact Effort Matrix

### Issue分割
INVEST / Vertical Slice / User Story Mapping

### UI/UX
G-STACK / HEART / Nielsen

### API設計
API First / Contract First / REST設計原則

### DB設計
正規化 / DDD Lite / データライフサイクル

### セキュリティ
OWASP Top 10 / STRIDE / 最小権限の原則

### テスト
テストピラミッド / リスクベーステスト / Given When Then

### 記事化
PREP / Before After / 課題→解決→学び

## 出力の基本形式

```md
## 使用したフレームワーク

- フレームワーク:
- 採用理由:

## 評価

## 計画

## 優先順位

## 次のアクション
```

## 関連

- `.claude/skills/framework-based-planning.md` — 具体的な選択ルールと出力ルール
- `CLAUDE.md` の「Framework-Based Planning Rule」セクション
