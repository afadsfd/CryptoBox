import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Web 平台的数据库连接
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    return WebDatabase('cryptofolio_db');
  });
}
