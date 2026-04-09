import 'package:drift/drift.dart';
import '../database.dart';

class PriceCacheRepository {
  final AppDatabase _db;
  PriceCacheRepository(this._db);

  // 获取缓存价格（60秒内有效）
  Future<Map<String, PriceCacheData>> getValidPrices(List<String> symbols) async {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 60));
    final results = await (_db.select(_db.priceCache)
          ..where((t) => t.symbol.isIn(symbols) & t.updatedAt.isBiggerOrEqualValue(cutoff)))
        .get();
    return {for (final r in results) r.symbol: r};
  }

  // 批量更新价格缓存
  Future<void> upsertPrices(Map<String, double> prices, {Map<String, double>? changes}) async {
    await _db.batch((batch) {
      for (final entry in prices.entries) {
        batch.insert(
          _db.priceCache,
          PriceCacheCompanion.insert(
            symbol: entry.key,
            priceUsd: entry.value,
            change24h: Value(changes?[entry.key] ?? 0.0),
            updatedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  // 清除所有缓存
  Future<int> clearAll() {
    return _db.delete(_db.priceCache).go();
  }
}
