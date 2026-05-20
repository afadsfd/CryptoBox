/// 同步过程中某个账户 / source 失败的提示
class PortfolioWarning {
  final String exchangeName;
  final String accountLabel;
  /// BalanceSource.storageKey，如 'spot' / 'earn_flexible' / 'futures_usdt'
  final String sourceLabel;
  final String message;

  const PortfolioWarning({
    required this.exchangeName,
    required this.accountLabel,
    required this.sourceLabel,
    required this.message,
  });
}

/// 资产组合概览
class PortfolioSummary {
  final double totalValueUsd;
  final double change24hUsd;
  final double change24hPercent;
  final int connectedExchanges;
  final int totalHoldings;
  final List<PortfolioWarning> warnings;

  const PortfolioSummary({
    required this.totalValueUsd,
    required this.change24hUsd,
    required this.change24hPercent,
    required this.connectedExchanges,
    required this.totalHoldings,
    this.warnings = const [],
  });

  /// 空 summary（无交易所绑定时使用）
  factory PortfolioSummary.empty() => const PortfolioSummary(
        totalValueUsd: 0,
        change24hUsd: 0,
        change24hPercent: 0,
        connectedExchanges: 0,
        totalHoldings: 0,
      );
}
