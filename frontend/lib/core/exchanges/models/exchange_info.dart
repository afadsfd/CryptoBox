/// 交易所基本信息模型
class ExchangeInfo {
  final String id; // binance, okx, bybit...
  final String name; // Binance, OKX, Bybit...
  final String logoUrl; // 交易所官方 logo URL
  final bool requiresPassphrase; // OKX, Bitget 需要

  const ExchangeInfo({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.requiresPassphrase = false,
  });

  /// 根据 id 查找
  static ExchangeInfo? findById(String id) {
    final key = id.toLowerCase();
    for (final e in supportedExchanges) {
      if (e.id == key) return e;
    }
    return null;
  }

  static const List<ExchangeInfo> supportedExchanges = [
    ExchangeInfo(
      id: 'binance',
      name: 'Binance',
      logoUrl:
          'https://assets.coingecko.com/markets/images/52/large/binance.jpg',
    ),
    ExchangeInfo(
      id: 'okx',
      name: 'OKX',
      logoUrl:
          'https://assets.coingecko.com/markets/images/96/large/WeChat_Image_20220117220452.png',
      requiresPassphrase: true,
    ),
    ExchangeInfo(
      id: 'bybit',
      name: 'Bybit',
      logoUrl:
          'https://assets.coingecko.com/markets/images/698/large/bybit_spot.png',
    ),
    ExchangeInfo(
      id: 'coinbase',
      name: 'Coinbase',
      logoUrl:
          'https://assets.coingecko.com/markets/images/23/large/Coinbase_Coin_Primary.png',
    ),
    ExchangeInfo(
      id: 'gateio',
      name: 'Gate',
      // CoinGecko 该资源易失效；CMC 静态图更稳定
      logoUrl:
          'https://s2.coinmarketcap.com/static/img/exchanges/200x200/302.png',
    ),
    ExchangeInfo(
      id: 'bitget',
      name: 'Bitget',
      logoUrl:
          'https://s2.coinmarketcap.com/static/img/exchanges/200x200/521.png',
      requiresPassphrase: true,
    ),
  ];
}
