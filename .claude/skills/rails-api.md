# Skill: Rails API 実装

OpenAPI に定義済みのエンドポイントを Rails で実装するときの進め方。

## 前提

- 対象 API は **OpenAPI に定義済み** であること。未定義なら api-design を先に。

## 判断基準

- ロジックは Controller でなく Model / Service に置くべきでは？
- 認可は Pundit Policy に集約できているか。
- レスポンスに内部 id が混ざっていないか。

## 進め方

1. OpenAPI の該当定義を確認する。
2. 必要ならマイグレーション（1 目的 1 ファイル、public_id + 一意インデックス）。
3. Model にバリデーション・関連・ロジックを置く。
4. Controller は薄く保ち、`authorize` で Pundit を呼ぶ。
5. レスポンス整形層で public_id を返す（内部 id を出さない）。
6. Request Spec を書く（testing スキル参照）。

## チェックリスト

- [ ] OpenAPI と入出力が一致している
- [ ] Controller が薄い（ロジックは Model/Service）
- [ ] 認可は Pundit Policy にある
- [ ] レスポンスは public_id（内部 id 非公開）
- [ ] N+1 を避けている（includes/preload）
- [ ] Request Spec が通る（正常 + 異常 + 認可）

## やってはいけない

- 認可ロジックを Controller に直書きする
- 内部 id をレスポンスに含める
- テストなしで完了とする
