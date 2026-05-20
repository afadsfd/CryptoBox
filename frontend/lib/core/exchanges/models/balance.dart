/// 资金来源。
///
/// `earn` / `futures` 保留为旧数据兼容和失败诊断的聚合类型；
/// 新同步数据优先使用更细的来源，避免把统一账户或 U 本位合约误标成现货。
enum BalanceSource {
  spot,
  funding,
  earn,
  earnFlexible,
  earnLocked,
  futures,
  futuresUsdt,
  futuresCoin,
  futuresUsdc,
  unified,
  margin,
  options,
  unknown,
}

const balanceSourceDisplayOrder = [
  BalanceSource.spot,
  BalanceSource.unified,
  BalanceSource.margin,
  BalanceSource.funding,
  BalanceSource.earnFlexible,
  BalanceSource.earnLocked,
  BalanceSource.earn,
  BalanceSource.futuresUsdt,
  BalanceSource.futuresUsdc,
  BalanceSource.futuresCoin,
  BalanceSource.futures,
  BalanceSource.options,
  BalanceSource.unknown,
];

BalanceSource balanceSourceFromStorage(String? value) {
  switch ((value ?? '').trim()) {
    case 'spot':
      return BalanceSource.spot;
    case 'funding':
      return BalanceSource.funding;
    case 'earn':
      return BalanceSource.earn;
    case 'earn_flexible':
    case 'earnFlexible':
      return BalanceSource.earnFlexible;
    case 'earn_locked':
    case 'earnLocked':
      return BalanceSource.earnLocked;
    case 'futures':
      return BalanceSource.futures;
    case 'futures_usdt':
    case 'futuresUsdt':
      return BalanceSource.futuresUsdt;
    case 'futures_coin':
    case 'futuresCoin':
      return BalanceSource.futuresCoin;
    case 'futures_usdc':
    case 'futuresUsdc':
      return BalanceSource.futuresUsdc;
    case 'unified':
      return BalanceSource.unified;
    case 'margin':
      return BalanceSource.margin;
    case 'options':
      return BalanceSource.options;
    case 'unknown':
      return BalanceSource.unknown;
    default:
      return BalanceSource.spot;
  }
}

extension BalanceSourceX on BalanceSource {
  String get storageKey {
    switch (this) {
      case BalanceSource.spot:
        return 'spot';
      case BalanceSource.funding:
        return 'funding';
      case BalanceSource.earn:
        return 'earn';
      case BalanceSource.earnFlexible:
        return 'earn_flexible';
      case BalanceSource.earnLocked:
        return 'earn_locked';
      case BalanceSource.futures:
        return 'futures';
      case BalanceSource.futuresUsdt:
        return 'futures_usdt';
      case BalanceSource.futuresCoin:
        return 'futures_coin';
      case BalanceSource.futuresUsdc:
        return 'futures_usdc';
      case BalanceSource.unified:
        return 'unified';
      case BalanceSource.margin:
        return 'margin';
      case BalanceSource.options:
        return 'options';
      case BalanceSource.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case BalanceSource.spot:
        return '现货';
      case BalanceSource.funding:
        return '资金账户';
      case BalanceSource.earn:
        return '理财';
      case BalanceSource.earnFlexible:
        return '活期理财';
      case BalanceSource.earnLocked:
        return '定期理财';
      case BalanceSource.futures:
        return '合约';
      case BalanceSource.futuresUsdt:
        return 'U本位合约';
      case BalanceSource.futuresCoin:
        return '币本位合约';
      case BalanceSource.futuresUsdc:
        return 'USDC合约';
      case BalanceSource.unified:
        return '统一账户';
      case BalanceSource.margin:
        return '杠杆账户';
      case BalanceSource.options:
        return '期权';
      case BalanceSource.unknown:
        return '未识别';
    }
  }

  bool get isEarnLike =>
      this == BalanceSource.earn ||
      this == BalanceSource.earnFlexible ||
      this == BalanceSource.earnLocked;

  bool get isFuturesLike =>
      this == BalanceSource.futures ||
      this == BalanceSource.futuresUsdt ||
      this == BalanceSource.futuresCoin ||
      this == BalanceSource.futuresUsdc;

  bool get isSupportedForSync => this != BalanceSource.unknown;

  int get sortOrder {
    final index = balanceSourceDisplayOrder.indexOf(this);
    return index < 0 ? balanceSourceDisplayOrder.length : index;
  }
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
      'Balance($symbol: total=$total, free=$free, locked=$locked, source=${source.storageKey})';
}
