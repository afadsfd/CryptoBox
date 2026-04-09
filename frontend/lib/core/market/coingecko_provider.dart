import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coingecko_service.dart';

/// CoinGecko 价格服务的全局 Provider
final coingeckoServiceProvider = Provider<CoinGeckoService>((ref) {
  final service = CoinGeckoService();
  ref.onDispose(() => service.dispose());
  return service;
});
