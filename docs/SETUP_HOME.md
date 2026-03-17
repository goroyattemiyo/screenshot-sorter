# 自宅環境セットアップ手順

## 前提
- Windows PC
- Android実機（USB接続可能）

## Step 1: Flutter SDKインストール
1. https://docs.flutter.dev/get-started/install/windows/mobile にアクセス
2. Flutter SDK をダウンロード＆展開（例: C:\flutter）
3. 環境変数PATHに C:\flutter\bin を追加
4. コマンドプロンプトで flutter doctor を実行

## Step 2: Android Studio インストール
1. https://developer.android.com/studio からダウンロード
2. インストール時に「Android SDK」「Android SDK Command-line Tools」を選択
3. Android Studio起動 → SDK Manager → SDK Platforms → Android 14 (API 34) をインストール
4. SDK Tools → 「Android SDK Build-Tools」「Android SDK Command-line Tools」にチェック

## Step 3: Android実機の準備
1. スマホの「設定」→「デバイス情報」→「ビルド番号」を7回タップ → 開発者モードON
2. 「設定」→「開発者向けオプション」→「USBデバッグ」をON
3. USBケーブルでPCに接続
4. スマホに表示される「USBデバッグを許可しますか？」→ 許可

## Step 4: リポジトリクローン＆実行

    git clone https://github.com/goroyattemiyo/screenshot-sorter.git
    cd screenshot-sorter
    flutter pub get
    flutter doctor
    flutter devices
    flutter run

## Step 5: 動作確認手順
1. アプリが実機にインストールされる
2. ホームに戻る
3. 適当にスクリーンショットを撮影
4. 撮影後の通知 or ギャラリーから「共有」をタップ
5. 共有先に「Screenshot Sorter」が表示される
6. タップするとフォルダ選択画面が開く
7. フォルダを選択（または新規作成）→ 保存完了

## トラブルシューティング
- flutter doctor でエラーが出る → 指示に従ってライセンス承認: flutter doctor --android-licenses
- デバイスが認識されない → USBドライバをメーカーサイトからインストール
- ビルドエラー → flutter clean してから flutter pub get でリトライ
