import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_storage/database_provider.dart';
import 'coingecko_service.dart';

/// CoinGecko 价格服务的全局 Provider
///
/// 启动时从 DB 恢复已缓存的图标 URL，
/// 新拉取的 URL 也会自动写回 DB。
final coingeckoServiceProvider = Provider<CoinGeckoService>((ref) {
  final service = CoinGeckoService();
  final priceCacheRepo = ref.read(priceCacheRepositoryProvider);

  // 从 DB 恢复图标 URL 到内存缓存（异步，但很快）
  priceCacheRepo.getAllImageUrls().then((urls) {
    service.restoreImageUrlCache(urls);
  }).catchError((Object e) {
    debugPrint('Failed to restore image URL cache: $e');
  });

  // 当 CoinGecko 拉取到新图标 URL 时，写入 DB
  service.onImageUrlsFetched = (urls) {
    priceCacheRepo.upsertImageUrls(urls).catchError((Object e) {
      debugPrint('Failed to persist image URLs: $e');
    });
  };

  ref.onDispose(() => service.dispose());
  return service;
});
