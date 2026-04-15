/// 资金来源：现货 / 理财 / 合约
enum BalanceSource {
  spot,
  earn,
  futures,
}

/// Balance 和缓存余额的共同接口
abstract class BalanceLike {
  String get symbol;
  double get total;
  double get free;
  double get locked;
}

/// 交易所账户余额模型
class Balance implements BalanceLike {
  @override
  final String symbol; // BTC, ETH, USDT...
  @override
  final double total;
  @override
  final double free;
  @override
  final double locked;

  /// 资金来源（默认现货，用于后续 UI 展示 / 排查）
  final BalanceSource source;

  Balance({
    required this.symbol,
    required this.total,
    required this.free,
    required this.locked,
    this.source = BalanceSource.spot,
  });

  Balance copyWith({
    String? symbol,
    double? total,
    double? free,
    double? locked,
    BalanceSource? source,
  }) =>
      Balance(
        symbol: symbol ?? this.symbol,
        total: total ?? this.total,
        free: free ?? this.free,
        locked: locked ?? this.locked,
        source: source ?? this.source,
      );

  @override
  String toString() =>
      'Balance($symbol: total=$total, free=$free, locked=$locked, source=${source.name})';
}
