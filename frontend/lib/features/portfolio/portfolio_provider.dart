import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exchanges/exchange_provider.dart';
import '../../core/local_storage/database_provider.dart';
import '../../core/market/coingecko_provider.dart';
import '../../core/security/security_provider.dart';
import 'portfolio_service.dart';

/// Portfolio 聚合服务 Provider
final portfolioServiceProvider = Provider<PortfolioService>((ref) {
  return PortfolioService(
    exchangeRepository: ref.watch(exchangeRepositoryProvider),
    holdingRepository: ref.watch(holdingRepositoryProvider),
    snapshotRepository: ref.watch(snapshotRepositoryProvider),
    priceCacheRepository: ref.watch(priceCacheRepositoryProvider),
    exchangeService: ref.watch(exchangeServiceProvider),
    coingeckoService: ref.watch(coingeckoServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
});
