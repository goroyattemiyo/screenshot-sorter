# Screenshot Sorter - 設計判断ログ

---

## D-001: 技術選定・アーキテクチャ設計

- **日付**: 2026-03-17
- **背景**: スクショ即振り分けアプリのMVP技術選定
- **召喚有識者**: モバイルアーキテクト / UXデザイナー / セキュリティ専門家 / ビジネスアナリスト

### 選択肢

| # | 選択肢 | 利点 | 欠点 |
|---|--------|------|------|
| A | Flutter | 1コードベース両OS、receive_sharing_intentあり | iOS Share Extension一部ネイティブ必要の可能性 |
| B | ネイティブ（Swift+Kotlin） | OS機能フルアクセス | 開発コスト2倍 |
| C | React Native | クロスプラットフォーム | 共有シート連携パッケージの成熟度低 |

### 決定
**Flutter** を採用

### 理由
- MVP機能がシンプルでネイティブ固有の複雑処理が少ない
- receive_sharing_intentが両OS共有シート連携を抽象化
- 単一コードベースで開発速度・保守性向上

### スコアリング

| # | 評価項目 | スコア |
|---|----------|--------|
| 1 | 技術的妥当性 | 9/10 |
| 2 | 保守性・可読性 | 8/10 |
| 3 | スコープ適合性 | 5/5 |
| 4 | テスト容易性 | 4/5 |
| 5 | リスク・副作用 | 4/5 |
| 6 | 費用対効果 | 5/5 |
| | **合計** | **35/40 (87.5%) → 着手許可** |

### 技術詳細

| 項目 | 選定 |
|------|------|
| フレームワーク | Flutter |
| 言語 | Dart |
| 共有シート | receive_sharing_intent |
| Android保存 | MediaStore API (RELATIVE_PATH) |
| iOS保存 | PHPhotoLibrary + PHAssetCollection |
| 状態管理 | D-002で決定 |
| サーバー | なし（MVP） |

### iOS実装の注意
- PHAssetCollectionChangeRequest.creationRequestForAssetCollection でアルバム作成
- PHAssetChangeRequest.creationRequestForAsset で画像追加
- ユーザー向けには「フォルダ」表記（「アルバム」は使わない）
