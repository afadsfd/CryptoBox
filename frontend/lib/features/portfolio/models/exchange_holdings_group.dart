import '../../../core/exchanges/models/balance.dart';

/// 单个交易所账户下的一条持仓（服务层）
class AccountHoldingLine {
  final String symbol;
  final double quantity;
  final double priceUsd;
  final double valueUsd;
  final double? change24h;

  /// 资金来源：spot / earn / futures
  final BalanceSource source;

  const AccountHoldingLine({
    required this.symbol,
    required this.quantity,
    required this.priceUsd,
    required this.valueUsd,
    this.change24h,
    this.source = BalanceSource.spot,
  });
}

/// 按来源（spot/earn/futures）分组的子组
class SourceHoldingsSubGroup {
  final BalanceSource source;
  final double totalValueUsd;
  final List<AccountHoldingLine> holdings;

  const SourceHoldingsSubGroup({
    required this.source,
    required this.totalValueUsd,
    required this.holdings,
  });
}

/// 按交易所账户分组的持仓
class ExchangeHoldingsGroup {
  final String accountId;
  final String label;
  final String exchangeId;
  final String displayName;
  final String logoUrl;
  final double totalValueUsd;
  final List<AccountHoldingLine> holdings;

  /// 按资金来源拆分的子分组（spot/earn/futures）
  final List<SourceHoldingsSubGroup> sourceGroups;

  const ExchangeHoldingsGroup({
    required this.accountId,
    required this.label,
    required this.exchangeId,
    required this.displayName,
    required this.logoUrl,
    required this.totalValueUsd,
    required this.holdings,
    this.sourceGroups = const [],
  });
}
