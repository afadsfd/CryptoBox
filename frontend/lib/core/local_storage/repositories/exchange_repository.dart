import 'package:drift/drift.dart';
import '../database.dart';

class ExchangeRepository {
  final AppDatabase _db;
  ExchangeRepository(this._db);

  // 获取所有活跃账户
  Future<List<ExchangeAccount>> getActiveAccounts() {
    return (_db.select(_db.exchangeAccounts)
          ..where((t) => t.isActive.equals(true)))
        .get();
  }

  // 获取所有账户
  Future<List<ExchangeAccount>> getAllAccounts() {
    return _db.select(_db.exchangeAccounts).get();
  }

  // 根据 ID 获取
  Future<ExchangeAccount?> getById(String id) {
    return (_db.select(_db.exchangeAccounts)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // 插入或更新
  Future<void> upsert(ExchangeAccountsCompanion entry) {
    return _db.into(_db.exchangeAccounts).insertOnConflictUpdate(entry);
  }

  // 删除
  Future<int> deleteById(String id) {
    return (_db.delete(_db.exchangeAccounts)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // 更新同步时间
  Future<void> updateSyncTime(String id) {
    return (_db.update(_db.exchangeAccounts)
          ..where((t) => t.id.equals(id)))
        .write(ExchangeAccountsCompanion(
          lastSyncAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }
}
