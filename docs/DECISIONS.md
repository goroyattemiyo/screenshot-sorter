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

## D-002: Flutter状態管理方式の選定

| 項目 | 内容 |
|------|------|
| 日付 | 2026-03-17 |
| ステータス | 承認 |
| スコア | 37/40 (92.5%) |

### 背景
MVP（共有シート→フォルダ選択→保存）のFlutter状態管理方式を選定する。

### 選択肢
1. **Riverpod** — 型安全、テスト容易、依存少、拡張性高
2. **Bloc** — テスト容易だがボイラープレート過多、この規模には過剰
3. **setState + InheritedWidget** — 最小構成だがPhase 2拡張に耐えない

### 決定
**Riverpod（flutter_riverpod）を採用**

### 理由
- 画面数1〜2、状態は画像パス・フォルダ一覧・選択状態・保存状態の4つでシンプル
- Riverpodは小規模でもオーバーヘッドが少なく、Phase 2（クラウド連携）追加時にProvider拡張で対応可能
- Providerのモックが容易でUnit Test記述しやすい
- 依存は flutter_riverpod + riverpod の2パッケージのみ

### スコア内訳
| 評価軸 | 配点 | スコア |
|--------|------|--------|
| 技術的適合性 | /10 | 9 |
| 保守性 | /10 | 9 |
| スコープ適合性 | /5 | 5 |
| テスト容易性 | /5 | 5 |
| リスク | /5 | 4 |
| コスト効率 | /5 | 5 |
| **合計** | **/40** | **37** |

## D-003: Flutterプロジェクト構成

| 項目 | 内容 |
|------|------|
| 日付 | 2026-03-17 |
| ステータス | 承認 |
| スコア | 38/40 (95%) |

### 背景
既存リポジトリ（docs/、README.md）にFlutterプロジェクトを統合する方式を選定。

### 選択肢
1. **リポジトリルートに生成** — flutterコマンドがそのまま使える、CI設定シンプル
2. **サブディレクトリ（app/）に生成** — コード分離は明確だが毎回cd必要

### 決定
**リポジトリルートに生成**（`flutter create . --org com.goroyattemiyo --project-name screenshot_sorter --platforms android,ios`）

### 理由
- この規模ではサブディレクトリ分離のメリットが薄い
- flutter test / flutter build がルートで即実行可能
- GitHub Actions設定でworking-directory指定不要

## D-004: 共有シート連携パッケージの選定

| 項目 | 内容 |
|------|------|
| 日付 | 2026-03-17 |
| ステータス | 承認 |
| スコア | 35/40 (87.5%) |

### 選択肢
1. **receive_sharing_intent** — 実績多いが最終更新2024/10、メンテ停滞
2. **share_handler** — Federated plugin構成、メンテ継続、Direct Share対応
3. **receive_sharing_intent_plus** — fork版、安定性未知数

### 決定
**share_handler を採用**

### 理由
- Federated plugin構成でプラットフォーム別テスト可能
- メンテナンスが継続されておりFlutter最新版との互換性リスクが低い
- Direct Share対応で将来の拡張性あり
