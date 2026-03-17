# 開発計画: Screenshot Sorter

## プロジェクト概要
スクショ撮影直後、OS共有シートから起動し、端末内の任意フォルダに即座に振り分けるアプリ。

## 技術スタック

| 項目 | 選定 | 決定番号 |
|------|------|----------|
| フレームワーク | Flutter | D-001 |
| 状態管理 | Riverpod v3 (Notifier) | D-002 |
| プロジェクト構成 | リポジトリルート | D-003 |
| 共有シート連携 | share_handler | D-004 |
| ローカル保存(Android) | File I/O (Pictures配下) | - |
| 履歴永続化 | shared_preferences | - |

## Phase 1 (MVP) 進捗

| Issue | タスク | ステータス |
|-------|--------|------------|
| #1 | 共有シート: Android intent-filter | 完了 |
| #2 | 共有シート: iOS Share Extension | blocked(Mac無し) |
| #3 | フォルダ一覧表示（直近使用順） | 実装済 |
| #4 | フォルダ新規作成機能 | 実装済 |
| #5 | 画像保存（フォルダ選択→端末内保存） | Android実装済 / iOS未 |
| - | UIモックアップ | 完了（docs/ui_mockup.html） |
| - | Android実機テスト | 次のステップ |

## 次のアクション（自宅作業）
1. Windows PCにFlutter環境構築（docs/SETUP_HOME.md参照）
2. リポジトリclone
3. Android実機でビルド＆動作確認
4. 不具合修正・UX改善
5. MediaStore API対応検討（ギャラリー反映）

## ファイル構成

    screenshot-sorter/
    ├── README.md
    ├── .gitignore
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── docs/
    │   ├── RULES.md
    │   ├── DEVELOPMENT_PLAN.md
    │   ├── DECISIONS.md
    │   ├── BACKLOG.md
    │   ├── HEARING_SHEET.md
    │   ├── SETUP_HOME.md
    │   └── ui_mockup.html
    ├── lib/
    │   ├── main.dart
    │   ├── providers/
    │   │   ├── share_provider.dart
    │   │   └── folder_provider.dart
    │   ├── screens/
    │   │   └── folder_select_screen.dart
    │   └── services/
    │       └── image_save_service.dart
    ├── test/
    │   └── widget_test.dart
    ├── android/ (intent-filter設定済)
    └── ios/ (Share Extension未設定)

## Phase ロードマップ

| Phase | 内容 | 状態 |
|-------|------|------|
| Phase 1 | 共有シート→フォルダ選択→端末保存 | 実装中（実機テスト待ち） |
| Phase 2 | Google Drive連携 | 未着手 |
| Phase 3 | モザイク処理・AI提案 | 未着手 |
