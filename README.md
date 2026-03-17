# Screenshot Sorter

スクショ撮影直後、OS共有シートから起動し、端末内の任意フォルダに即座に振り分けるアプリ。

## ステータス

| 項目 | 状態 |
|------|------|
| フェーズ | Phase 1 (MVP) |
| 技術選定 | D-001 完了 → Flutter |
| 実装 | 未着手（ヒアリングシートFB待ち） |

## ドキュメント

| ファイル | 内容 |
|----------|------|
| [docs/RULES.md](docs/RULES.md) | 開発ルール |
| [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) | 開発計画・現在の状態 |
| [docs/DECISIONS.md](docs/DECISIONS.md) | 設計判断ログ |
| [docs/BACKLOG.md](docs/BACKLOG.md) | バックログ |
| [docs/HEARING_SHEET.md](docs/HEARING_SHEET.md) | クライアントヒアリングシート |

## 開発ルール（dev-rules準拠）

1. **コード即書き禁止**: 有識者議論とスコアリング8割以上で初めて着手
2. **ハルシネーション禁止**: ファイルパス・関数名は実在確認してから使用
3. **スコープロック**: 現タスク外の改善提案はBACKLOG.mdへ
4. **セッション開始プロトコル**: 毎回RULES.mdとDEVELOPMENT_PLAN.mdを再読み込み

## 技術スタック

| 項目 | 選定 |
|------|------|
| フレームワーク | Flutter |
| 言語 | Dart |
| 共有シート受け取り | receive_sharing_intent |
| Android保存 | MediaStore API |
| iOS保存 | PHPhotoLibrary |
| サーバー | なし（MVP） |
