import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';

/// 共有シートから受け取った画像パスを管理するプロバイダー
final sharedMediaProvider =
    NotifierProvider<SharedMediaNotifier, SharedMedia?>(
  SharedMediaNotifier.new,
);

class SharedMediaNotifier extends Notifier<SharedMedia?> {
  StreamSubscription? _sub;

  @override
  SharedMedia? build() => null;

  /// 共有Intentのリスニングを開始
  void init() {
    final handler = ShareHandlerPlatform.instance;

    // アプリ起動時（コールドスタート）の共有データ取得
    handler.getInitialSharedMedia().then((media) {
      if (media != null) {
        state = media;
      }
    });

    // アプリがメモリ上にある時の共有データ受信
    _sub = handler.sharedMediaStream.listen((media) {
      state = media;
    });
  }

  /// 処理完了後にリセット
  void reset() {
    ShareHandlerPlatform.instance.resetInitialSharedMedia();
    state = null;
  }

  /// ストリーム購読を解除
  void cancelSubscription() {
    _sub?.cancel();
  }
}
