import 'package:drift/drift.dart';
import '../database.dart';

class SnapshotRepository {
  final AppDatabase _db;
  SnapshotRepository(this._db);

  // 保存快照
  Future<void> insert(PortfolioSnapshotsCompanion entry) {
    return _db.into(_db.portfolioSnapshots).insert(entry);
  }

  // 获取指定天数的快照
  Future<List<PortfolioSnapshot>> getRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (_db.select(_db.portfolioSnapshots)
          ..where((t) => t.snapshotAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.asc(t.snapshotAt)]))
        .get();
  }

  // 获取所有快照
  Future<List<PortfolioSnapshot>> getAll() {
    return (_db.select(_db.portfolioSnapshots)
          ..orderBy([(t) => OrderingTerm.asc(t.snapshotAt)]))
        .get();
  }

  // 删除所有
  Future<int> deleteAll() {
    return _db.delete(_db.portfolioSnapshots).go();
  }
}
