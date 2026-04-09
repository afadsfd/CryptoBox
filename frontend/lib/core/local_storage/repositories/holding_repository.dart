import '../database.dart';

class HoldingRepository {
  final AppDatabase _db;
  HoldingRepository(this._db);

  // 获取某个交易所的所有持仓
  Future<List<Holding>> getByExchangeId(String exchangeAccountId) {
    return (_db.select(_db.holdings)
          ..where((t) => t.exchangeAccountId.equals(exchangeAccountId)))
        .get();
  }

  // 获取所有持仓
  Future<List<Holding>> getAll() {
    return _db.select(_db.holdings).get();
  }

  // 批量插入/更新（先删除该交易所旧数据，再插入新数据）
  Future<void> replaceForExchange(String exchangeAccountId, List<HoldingsCompanion> entries) async {
    await _db.transaction(() async {
      await (_db.delete(_db.holdings)
            ..where((t) => t.exchangeAccountId.equals(exchangeAccountId)))
          .go();
      for (final entry in entries) {
        await _db.into(_db.holdings).insert(entry);
      }
    });
  }

  // 删除某个交易所的所有持仓
  Future<int> deleteByExchangeId(String exchangeAccountId) {
    return (_db.delete(_db.holdings)
          ..where((t) => t.exchangeAccountId.equals(exchangeAccountId)))
        .go();
  }

  // 删除所有
  Future<int> deleteAll() {
    return _db.delete(_db.holdings).go();
  }
}
