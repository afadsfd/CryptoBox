import 'balance.dart';

enum AssetSupportLevel {
  stable,
  beta,
  partial,
  planned,
  unsupported,
}

extension AssetSupportLevelX on AssetSupportLevel {
  String get label {
    switch (this) {
      case AssetSupportLevel.stable:
        return '稳定';
      case AssetSupportLevel.beta:
        return 'Beta';
      case AssetSupportLevel.partial:
        return '部分';
      case AssetSupportLevel.planned:
        return '待补';
      case AssetSupportLevel.unsupported:
        return '不支持';
    }
  }

  bool get isAvailable =>
      this == AssetSupportLevel.stable ||
      this == AssetSupportLevel.beta ||
      this == AssetSupportLevel.partial;
}

class ExchangeAssetSupport {
  final BalanceSource source;
  final AssetSupportLevel level;
  final String note;

  const ExchangeAssetSupport({
    required this.source,
    required this.level,
    this.note = '',
  });

  bool get isAvailable => level.isAvailable;
}

/// 交易所基本信息模型
class ExchangeInfo {
  final String id; // binance, okx, bybit...
  final String name; // Binance, OKX, Bybit...
  final String logoUrl; // 交易所官方 logo URL
  final bool requiresPassphrase; // OKX, Bitget 需要
  final List<ExchangeAssetSupport> assetSupport;

  const ExchangeInfo({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.requiresPassphrase = false,
    this.assetSupport = const [],
  });

  /// 根据 id 查找
  static ExchangeInfo? findById(String id) {
    final key = id.toLowerCase();
    for (final e in supportedExchanges) {
      if (e.id == key) return e;
    }
    return null;
  }

  List<ExchangeAssetSupport> get visibleAssetSupport =>
      assetSupport
        .where((s) => s.level != AssetSupportLevel.unsupported)
        .toList()
        ..sort((a, b) => a.source.sortOrder.compareTo(b.source.sortOrder));

  bool supportsSource(BalanceSource source) {
    for (final s in assetSupport) {
      if (s.source == source && s.isAvailable) return true;
    }
    return false;
  }

  static const List<ExchangeInfo> supportedExchanges = [
    ExchangeInfo(
      id: 'binance',
      name: 'Binance',
      logoUrl:
          'https://assets.coingecko.com/markets/images/52/large/binance.jpg',
      assetSupport: [
        ExchangeAssetSupport(
          source: BalanceSource.spot,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.funding,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.earnFlexible,
          level: AssetSupportLevel.beta,
          note: '需要开启 Simple Earn 读取权限',
        ),
        ExchangeAssetSupport(
          source: BalanceSource.earnLocked,
          level: AssetSupportLevel.beta,
          note: '需要开启 Simple Earn 读取权限',
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futuresUsdt,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futuresCoin,
          level: AssetSupportLevel.stable,
        ),
      ],
    ),
    ExchangeInfo(
      id: 'okx',
      name: 'OKX',
      logoUrl:
          'https://assets.coingecko.com/markets/images/96/large/WeChat_Image_20220117220452.png',
      requiresPassphrase: true,
      assetSupport: [
        ExchangeAssetSupport(
          source: BalanceSource.unified,
          level: AssetSupportLevel.partial,
          note: '统一账户混合现货/合约/杠杆/期权净值',
        ),
        ExchangeAssetSupport(
          source: BalanceSource.funding,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.earnFlexible,
          level: AssetSupportLevel.beta,
        ),
      ],
    ),
    ExchangeInfo(
      id: 'bybit',
      name: 'Bybit',
      logoUrl:
          'https://assets.coingecko.com/markets/images/698/large/bybit_spot.png',
      assetSupport: [
        ExchangeAssetSupport(
          source: BalanceSource.unified,
          level: AssetSupportLevel.partial,
          note: 'UNIFIED 账户混合现货和衍生品保证金',
        ),
        ExchangeAssetSupport(
          source: BalanceSource.funding,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.earn,
          level: AssetSupportLevel.planned,
          note: '官方 Earn 口径分散，暂不承诺',
        ),
      ],
    ),
    ExchangeInfo(
      id: 'coinbase',
      name: 'Coinbase',
      logoUrl:
          'https://assets.coingecko.com/markets/images/23/large/Coinbase_Coin_Primary.png',
      assetSupport: [
        ExchangeAssetSupport(
          source: BalanceSource.spot,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futures,
          level: AssetSupportLevel.unsupported,
          note: '当前 Advanced Trade 账户接口不覆盖独立 futures 账户',
        ),
      ],
    ),
    ExchangeInfo(
      id: 'gateio',
      name: 'Gate',
      // CoinGecko 该资源易失效；CMC 静态图更稳定
      logoUrl:
          'https://s2.coinmarketcap.com/static/img/exchanges/200x200/302.png',
      assetSupport: [
        ExchangeAssetSupport(
          source: BalanceSource.spot,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futuresUsdt,
          level: AssetSupportLevel.beta,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futuresCoin,
          level: AssetSupportLevel.beta,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.earn,
          level: AssetSupportLevel.planned,
          note: '理财接口只给总估值，暂不按币种入账',
        ),
      ],
    ),
    ExchangeInfo(
      id: 'bitget',
      name: 'Bitget',
      logoUrl:
          'https://s2.coinmarketcap.com/static/img/exchanges/200x200/521.png',
      requiresPassphrase: true,
      assetSupport: [
        ExchangeAssetSupport(
          source: BalanceSource.spot,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futuresUsdt,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futuresUsdc,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.futuresCoin,
          level: AssetSupportLevel.stable,
        ),
        ExchangeAssetSupport(
          source: BalanceSource.earnFlexible,
          level: AssetSupportLevel.beta,
        ),
      ],
    ),
  ];
}
