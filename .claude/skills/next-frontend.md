# Skill: Next.js フロントエンド実装

OpenAPI に定義済みの API をフロントから使い、画面を作るときの進め方。

## 前提

- 利用する API は OpenAPI に定義済みで、backend 実装が済んでいること。
- デザインは V0 生成プロトタイプを基準にする（`docs/design-system.md`）。
  新規 UI は既存のトークン・レイアウト（AppShell）・共通コンポーネントに合わせる。

## 判断基準

- API の型は OpenAPI 由来か（`any` を使っていないか）。
- サーバー状態は TanStack Query で扱えているか。
- UI は shadcn/ui + Tailwind で組めるか。

## 進め方

1. 対象 API の OpenAPI 定義を確認し、型を用意する。
2. データ取得・更新は TanStack Query 経由で実装。
3. フォームは React Hook Form + Zod でバリデーション。
4. UI は shadcn/ui コンポーネント + Tailwind で構成。
5. API URL・秘密情報は環境変数から読む。

## チェックリスト

- [ ] App Router を使っている
- [ ] API の型が OpenAPI と一致（any を避ける）
- [ ] サーバー状態は TanStack Query
- [ ] フォームは RHF + Zod
- [ ] public_id を使い、内部 id に依存していない
- [ ] URL / 鍵をハードコードしていない
- [ ] ローディング / エラー状態を扱っている

## やってはいけない

- 内部 id 前提の実装
- 秘密情報のハードコード
- OpenAPI 未定義の API を勝手に叩く
