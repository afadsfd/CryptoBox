import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'repositories/exchange_repository.dart';
import 'repositories/holding_repository.dart';
import 'repositories/snapshot_repository.dart';
import 'repositories/price_cache_repository.dart';

// 数据库单例
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository Providers
final exchangeRepositoryProvider = Provider<ExchangeRepository>((ref) {
  return ExchangeRepository(ref.watch(databaseProvider));
});

final holdingRepositoryProvider = Provider<HoldingRepository>((ref) {
  return HoldingRepository(ref.watch(databaseProvider));
});

final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  return SnapshotRepository(ref.watch(databaseProvider));
});

final priceCacheRepositoryProvider = Provider<PriceCacheRepository>((ref) {
  return PriceCacheRepository(ref.watch(databaseProvider));
});
