/// 交易所基本信息模型
class ExchangeInfo {
  final String id; // binance, okx, bybit...
  final String name; // Binance, OKX, Bybit...
  final String logoUrl; // logo URL
  final bool requiresPassphrase; // OKX, Bitget 需要

  const ExchangeInfo({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.requiresPassphrase = false,
  });

  static const List<ExchangeInfo> supportedExchanges = [
    ExchangeInfo(
      id: 'binance',
      name: 'Binance',
      logoUrl: 'https://cryptologos.cc/logos/binance-coin-bnb-logo.png',
    ),
    ExchangeInfo(
      id: 'okx',
      name: 'OKX',
      logoUrl: 'https://cryptologos.cc/logos/okb-okb-logo.png',
      requiresPassphrase: true,
    ),
    ExchangeInfo(
      id: 'bybit',
      name: 'Bybit',
      logoUrl: 'https://cryptologos.cc/logos/bybit-logo.png',
    ),
    ExchangeInfo(
      id: 'coinbase',
      name: 'Coinbase',
      logoUrl: 'https://cryptologos.cc/logos/coinbase-coin-logo.png',
    ),
    ExchangeInfo(
      id: 'gateio',
      name: 'Gate.io',
      logoUrl: 'https://cryptologos.cc/logos/gate-token-gt-logo.png',
    ),
    ExchangeInfo(
      id: 'bitget',
      name: 'Bitget',
      logoUrl: 'https://cryptologos.cc/logos/bitget-token-bgb-logo.png',
      requiresPassphrase: true,
    ),
  ];
}
