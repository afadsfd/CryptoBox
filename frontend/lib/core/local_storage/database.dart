import 'package:drift/drift.dart';

// 条件导入：Web 平台使用 WebDatabase，原生平台使用 NativeDatabase
import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    as connection;

part 'database.g.dart';

// ============ 表定义 ============

class ExchangeAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get exchangeName => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  TextColumn get encryptedApiKey => text()();
  TextColumn get encryptedSecret => text()();
  TextColumn get encryptedPassphrase => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Holdings extends Table {
  TextColumn get id => text()();
  TextColumn get exchangeAccountId => text().references(ExchangeAccounts, #id)();
  TextColumn get symbol => text()();
  RealColumn get quantity => real().withDefault(const Constant(0.0))();
  RealColumn get free => real().withDefault(const Constant(0.0))();
  RealColumn get locked => real().withDefault(const Constant(0.0))();
  RealColumn get priceUsd => real().nullable()();
  RealColumn get valueUsd => real().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PortfolioSnapshots extends Table {
  TextColumn get id => text()();
  RealColumn get totalValueUsd => real()();
  DateTimeColumn get snapshotAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PriceCache extends Table {
  TextColumn get symbol => text()();
  RealColumn get priceUsd => real()();
  RealColumn get change24h => real().withDefault(const Constant(0.0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {symbol};
}

// ============ 数据库类 ============

@DriftDatabase(tables: [ExchangeAccounts, Holdings, PortfolioSnapshots, PriceCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  // 用于测试
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
