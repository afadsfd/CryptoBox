/// 单个交易所账户下的一条持仓（服务层）
class AccountHoldingLine {
  final String symbol;
  final double quantity;
  final double priceUsd;
  final double valueUsd;
  final double? change24h;

  const AccountHoldingLine({
    required this.symbol,
    required this.quantity,
    required this.priceUsd,
    required this.valueUsd,
    this.change24h,
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

  const ExchangeHoldingsGroup({
    required this.accountId,
    required this.label,
    required this.exchangeId,
    required this.displayName,
    required this.logoUrl,
    required this.totalValueUsd,
    required this.holdings,
  });
}
