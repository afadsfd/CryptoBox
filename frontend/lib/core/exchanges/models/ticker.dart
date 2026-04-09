/// 行情 Ticker 数据模型
class Ticker {
  final String symbol; // BTC/USDT
  final double lastPrice;
  final double? change24h; // 24h 涨跌百分比

  Ticker({
    required this.symbol,
    required this.lastPrice,
    this.change24h,
  });

  @override
  String toString() =>
      'Ticker($symbol: price=$lastPrice, change24h=$change24h)';
}
