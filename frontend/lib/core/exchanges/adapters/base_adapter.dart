import 'package:flutter/foundation.dart';

import '../models/balance.dart';
import '../models/ticker.dart';

/// 带诊断信息的余额拉取结果
///
/// 当 earn / futures 接口因 API Key 权限不足等原因失败时，
/// 主流程不应阻塞，但错误需要冒泡到 UI 层展示。
class BalanceFetchResult {
  final List<Balance> balances;

  /// 每个 source 的错误信息；null 表示该 source 成功
  /// 例：{BalanceSource.earn: 'HTTP 401: ...'}
  final Map<BalanceSource, String> errors;

  const BalanceFetchResult({
    required this.balances,
    this.errors = const {},
  });

  BalanceFetchResult.empty()
      : balances = const [],
        errors = const {};
}

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

  /// 获取全部账户余额（现货 + 理财 + 合约）—— 兼容旧 API，只返回余额列表
  Future<List<Balance>> getAllBalances({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    final result = await getAllBalancesDetailed(
      apiKey: apiKey,
      apiSecret: apiSecret,
      passphrase: passphrase,
    );
    return result.balances;
  }

  /// 获取全部账户余额（现货 + 理财 + 合约），并返回每个 source 的错误信息
  ///
  /// 保留 [BalanceSource] 信息，**只合并同 (symbol, source)** 的条目，
  /// 不跨 source 合并，便于上层区分展示。
  /// 子账户实现失败不阻塞其它账户的统计；失败原因记录在 [BalanceFetchResult.errors] 中，
  /// 便于上层提示用户"请检查 API 权限"。
  Future<BalanceFetchResult> getAllBalancesDetailed({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    final results = await Future.wait<_SourceCallResult>([
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

    final errors = <BalanceSource, String>{};
    final allBalances = <Balance>[];
    for (final r in results) {
      allBalances.addAll(r.balances);
      if (r.error != null) {
        errors[r.source] = r.error!;
      }
    }
    return BalanceFetchResult(
      balances: mergeBalancesBySource(allBalances),
      errors: errors,
    );
  }

  /// earn / futures 类接口的快速超时窗口 —— 避免用户没开权限时长时间等待
  static const Duration _nonSpotTimeout = Duration(seconds: 8);

  Future<_SourceCallResult> _safeCall(
    Future<List<Balance>> Function() fn,
    BalanceSource fallbackSource,
  ) async {
    try {
      // spot 保持原 timeout；earn/futures 8s 内必须返回
      final future = fallbackSource == BalanceSource.spot
          ? fn()
          : fn().timeout(_nonSpotTimeout);
      final list = await future;
      return _SourceCallResult(
        source: fallbackSource,
        balances: list
            .map((b) =>
                b.source == fallbackSource ? b : b.copyWith(source: fallbackSource))
            .toList(),
      );
    } catch (e, st) {
      debugPrint(
        '[$exchangeId] ${fallbackSource.name} balance fetch failed: $e\n$st',
      );
      return _SourceCallResult(
        source: fallbackSource,
        balances: const [],
        error: _humanizeError(e),
      );
    }
  }

  String _humanizeError(Object e) {
    final msg = e.toString();
    if (e is ExchangeAuthException) return '权限不足（请在交易所 API Key 设置中开启对应模块的读取权限）';
    if (msg.contains('401') || msg.contains('403')) {
      return '权限不足（HTTP 40x）';
    }
    if (msg.toLowerCase().contains('timeout')) return '请求超时';
    if (msg.toLowerCase().contains('socket') ||
        msg.toLowerCase().contains('network')) {
      return '网络不可用';
    }
    // 截断，防止日志刷屏
    return msg.length > 120 ? '${msg.substring(0, 120)}…' : msg;
  }

  /// 获取行情 ticker 数据
  Future<Map<String, Ticker>> getTickers(List<String> symbols);
}

/// 单个 source 拉取结果（内部使用）
class _SourceCallResult {
  final BalanceSource source;
  final List<Balance> balances;
  final String? error;
  const _SourceCallResult({
    required this.source,
    required this.balances,
    this.error,
  });
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
