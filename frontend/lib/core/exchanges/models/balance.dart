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

  Balance({
    required this.symbol,
    required this.total,
    required this.free,
    required this.locked,
  });

  @override
  String toString() =>
      'Balance($symbol: total=$total, free=$free, locked=$locked)';
}
