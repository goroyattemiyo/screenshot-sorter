# S3 - Screenshot Smart Sorter

スクリーンショットをフォルダに整理・管理するAndroidアプリ（Flutter製）

## 機能一覧

- 共有シートからの受け取り（連続保存対応）
- フォルダ選択・作成・削除・リネーム
- 画像保存（重複防止付き）
- フォルダ内画像一覧（枚数バッジ付き）
- 画像ビューア（スワイプ対応）
- 画像削除（長押し + 確認）
- Pull-to-refresh
- カラースライダー（ネオン虹色テーマ）
- 光量センサーでダーク/ライト自動切替
- 手動ダーク/ライト反転ボタン
- スプラッシュ画面（パステルデザイン）
- 既存ファイルマイグレーション

## 技術スタック

Flutter 3.x / Riverpod v3 / share_handler / SharedPreferences / light_sensor / Dart

## セットアップ

    git clone https://github.com/goroyattemiyo/screenshot-sorter.git
    cd screenshot-sorter
    flutter pub get
    flutter run

## ライセンス

MIT
