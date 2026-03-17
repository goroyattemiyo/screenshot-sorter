# Screenshot Sorter - 開発計画

最終更新: 2026-03-17

---

## 1. プロジェクト概要

### 1.1 アプリ名（仮称）
Screenshot Sorter

### 1.2 コンセプト
スクショ撮影直後、OS共有シートから起動し、端末内の任意フォルダに即座に振り分ける。

### 1.3 コアフロー

スクショ撮影 → 共有ボタン → 本アプリ選択 → フォルダ選択/新規作成 → 端末内保存


### 1.4 ターゲット
副業・SNS発信者（感想スクショ、売上実績スクショの整理）

---

## 2. フェーズ計画

### Phase 1: MVP（現在）

| # | 機能 | 詳細 | 状態 |
|---|------|------|------|
| 1 | 共有シート連携 | Android: intent-filter / iOS: Share Extension | 未着手 |
| 2 | フォルダ一覧表示 | 保存先フォルダをリスト表示（直近使用順） | 未着手 |
| 3 | フォルダ選択→保存 | タップで選択、即座に端末内に画像を保存 | 未着手 |
| 4 | フォルダ新規作成 | その場で作成して保存 | 未着手 |

### Phase 2: クラウド連携（将来）
- Google Drive保存 / お気に入りフォルダ / フォルダ内プレビュー

### Phase 3: 付加機能（将来）
- モザイク加工 / AI自動フォルダ提案 / 複数クラウド / SNS投稿

---

## 3. 技術スタック

| 項目 | 選定 | 根拠 |
|------|------|------|
| フレームワーク | Flutter | 両OS対応・単一コードベース |
| 言語 | Dart | Flutter標準 |
| 共有シート受け取り | receive_sharing_intent | 両OS抽象化済み |
| Android保存 | MediaStore API (RELATIVE_PATH) | Scoped Storage対応 |
| iOS保存 | PHPhotoLibrary + PHAssetCollection | カスタムアルバム |
| 状態管理 | D-002で決定予定 | |
| サーバー | なし（MVP） | 端末完結 |

---

## 4. アーキテクチャ

┌─────────────────────────────────────────┐ │ Presentation Layer (UI) │ │ - フォルダ選択画面 │ │ - 新規フォルダ作成ダイアログ │ │ - 保存完了トースト │ ├─────────────────────────────────────────┤ │ Application Layer (Use Cases) │ │ - ReceiveImageUseCase │ │ - SaveToFolderUseCase │ │ - CreateFolderUseCase │ │ - GetFolderListUseCase │ ├─────────────────────────────────────────┤ │ Domain Layer (Entities / Interfaces) │ │ - Folder (name, path, lastUsed) │ │ - ImageFile (uri, mimeType) │ │ - FolderRepository (interface) │ │ - ImageRepository (interface) │ ├─────────────────────────────────────────┤ │ Infrastructure Layer (Platform) │ │ - AndroidFolderRepository (MediaStore) │ │ - iOSFolderRepository (PHPhotoLibrary) │ │ - SharedIntentReceiver │ └─────────────────────────────────────────┘


### OS別の保存先

| OS | 保存先 | 技術 |
|----|--------|------|
| Android | Pictures/ScreenshotSorter/{フォルダ名}/ | MediaStore RELATIVE_PATH |
| iOS | 写真ライブラリ内カスタムアルバム | PHAssetCollection |

### iOS「フォルダ」の注意
iOSは「フォルダ」概念がない。写真ライブラリの「アルバム」として実現。
ユーザーには「フォルダ」と表示するが、内部はアルバム操作。

---

## 5. 権限要件

### Android
- READ_MEDIA_IMAGES（Android 13+）
- MediaStore経由の書き込み（追加権限不要）

### iOS
- NSPhotoLibraryAddUsageDescription
- NSPhotoLibraryUsageDescription

---

## 6. UX設計方針

### 目標
- スクショ〜保存完了: **3タップ、3秒以内**
- フォルダ新規作成込み: **5タップ、5秒以内**

### 画面構成（MVP）
1. **フォルダ選択画面**: 直近使用フォルダ上部、リスト表示、「+新規フォルダ」常時表示
2. **新規フォルダ作成ダイアログ**: 名前入力→作成＆即保存
3. **保存完了トースト**: 自動で元アプリに戻る

---

## 7. 現在の状態

- [x] ヒアリングシート作成・クライアント確認中
- [x] 競合調査完了
- [x] 技術調査完了
- [x] D-001 技術選定完了 → 着手許可（35/40）
- [ ] クライアントFB待ち
- [ ] D-002: 状態管理選定
- [ ] Flutterプロジェクト初期セットアップ
- [ ] Phase 1 実装着手

---

## 8. Next Steps

1. クライアントFB反映
2. D-002: 状態管理の有識者議論
3. flutter create でプロジェクト作成
4. 共有シート連携PoC
5. フォルダ保存PoC（Android: MediaStore / iOS: PHPhotoLibrary）
