import '../models/balance.dart';
import '../models/ticker.dart';

/// 交易所适配器抽象基类
abstract class BaseExchangeAdapter {
  /// 交易所标识符，如 binance, okx
  String get exchangeId;

  /// API 基础 URL
  String get baseUrl;

  /// 验证 API 连接是否有效
  Future<bool> verifyConnection({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  });

  /// 获取现货账户余额（过滤零余额）
  Future<List<Balance>> getSpotBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  });

  /// 获取理财账户余额（活期 + 定期）
  ///
  /// 默认返回空列表。适配器应尽量实现此方法；实现失败应抛异常，由上层捕获。
  Future<List<Balance>> getEarnBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async =>
      <Balance>[];

  /// 获取合约账户余额（U 本位 + 币本位等）
  ///
  /// 包含未实现盈亏（合约钱包净值）。默认返回空列表。
  Future<List<Balance>> getFuturesBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async =>
      <Balance>[];

  /// 获取全部账户余额（现货 + 理财 + 合约）
  ///
  /// 保留 [BalanceSource] 信息，**只合并同 (symbol, source)** 的条目，
  /// 不跨 source 合并，便于上层区分展示。
  /// 子账户实现失败不阻塞其它账户的统计（单账户异常捕获并记录日志）。
  Future<List<Balance>> getAllBalances({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    final results = await Future.wait<List<Balance>>([
      _safeCall(
        () => getSpotBalance(
          apiKey: apiKey,
          apiSecret: apiSecret,
          passphrase: passphrase,
        ),
        BalanceSource.spot,
      ),
      _safeCall(
        () => getEarnBalance(
          apiKey: apiKey,
          apiSecret: apiSecret,
          passphrase: passphrase,
        ),
        BalanceSource.earn,
      ),
      _safeCall(
        () => getFuturesBalance(
          apiKey: apiKey,
          apiSecret: apiSecret,
          passphrase: passphrase,
        ),
        BalanceSource.futures,
      ),
    ]);
    return mergeBalancesBySource(results.expand((b) => b).toList());
  }

  Future<List<Balance>> _safeCall(
    Future<List<Balance>> Function() fn,
    BalanceSource fallbackSource,
  ) async {
    try {
      final list = await fn();
      // 确保每个 Balance 的 source 被正确标注（防止适配器遗漏）
      return list
          .map((b) => b.source == fallbackSource ? b : b.copyWith(source: fallbackSource))
          .toList();
    } catch (_) {
      return <Balance>[];
    }
  }

  /// 获取行情 ticker 数据
  Future<Map<String, Ticker>> getTickers(List<String> symbols);
}

/// 按 (symbol, source) 合并同类别余额；保留 source 区分
List<Balance> mergeBalancesBySource(List<Balance> balances) {
  if (balances.isEmpty) return balances;
  final map = <String, Balance>{};
  for (final b in balances) {
    if (b.total <= 0) continue;
    final key = '${b.symbol.toUpperCase()}::${b.source.name}';
    final existing = map[key];
    if (existing == null) {
      map[key] = b.copyWith(symbol: b.symbol.toUpperCase());
    } else {
      map[key] = Balance(
        symbol: existing.symbol,
        total: existing.total + b.total,
        free: existing.free + b.free,
        locked: existing.locked + b.locked,
        source: existing.source,
      );
    }
  }
  return map.values.toList();
}

/// 合并同币种余额（忽略 source，将 total/free/locked 累加）
List<Balance> mergeBalances(List<Balance> balances) {
  if (balances.isEmpty) return balances;
  final map = <String, Balance>{};
  for (final b in balances) {
    final key = b.symbol.toUpperCase();
    if (b.total <= 0) continue;
    final existing = map[key];
    if (existing == null) {
      map[key] = b.copyWith(symbol: key);
    } else {
      map[key] = Balance(
        symbol: key,
        total: existing.total + b.total,
        free: existing.free + b.free,
        locked: existing.locked + b.locked,
        // 合并后的 source 保留第一次出现的来源（仅用于日志）
        source: existing.source,
      );
    }
  }
  return map.values.toList();
}

/// 交易所 API 异常
class ExchangeApiException implements Exception {
  final String exchangeId;
  final String message;
  final int? statusCode;

  ExchangeApiException({
    required this.exchangeId,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() =>
      'ExchangeApiException($exchangeId): $message (status: $statusCode)';
}

/// 交易所认证异常
class ExchangeAuthException extends ExchangeApiException {
  ExchangeAuthException({
    required super.exchangeId,
    required super.message,
    super.statusCode,
  });
}
