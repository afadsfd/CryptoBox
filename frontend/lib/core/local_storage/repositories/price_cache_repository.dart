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

  /// 获取所有已缓存的图标 URL（不受时间过期限制）
  Future<Map<String, String>> getAllImageUrls() async {
    final results = await (_db.select(_db.priceCache)
          ..where((t) => t.imageUrl.isNotNull()))
        .get();
    final map = <String, String>{};
    for (final r in results) {
      if (r.imageUrl != null && r.imageUrl!.isNotEmpty) {
        map[r.symbol] = r.imageUrl!;
      }
    }
    return map;
  }

  // 批量更新价格缓存
  Future<void> upsertPrices(
    Map<String, double> prices, {
    Map<String, double>? changes,
    Map<String, String>? imageUrls,
  }) async {
    await _db.batch((batch) {
      for (final entry in prices.entries) {
        batch.insert(
          _db.priceCache,
          PriceCacheCompanion.insert(
            symbol: entry.key,
            priceUsd: entry.value,
            change24h: Value(changes?[entry.key] ?? 0.0),
            imageUrl: Value(imageUrls?[entry.key]),
            updatedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 仅更新图标 URL（不覆盖价格和涨跌）
  Future<void> upsertImageUrls(Map<String, String> imageUrls) async {
    await _db.batch((batch) {
      for (final entry in imageUrls.entries) {
        batch.insert(
          _db.priceCache,
          PriceCacheCompanion(
            symbol: Value(entry.key),
            imageUrl: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          onConflict: DoUpdate(
            (old) => PriceCacheCompanion(
              imageUrl: Value(entry.value),
            ),
            target: [_db.priceCache.symbol],
          ),
        );
      }
    });
  }

  // 清除所有缓存
  Future<int> clearAll() {
    return _db.delete(_db.priceCache).go();
  }
}
