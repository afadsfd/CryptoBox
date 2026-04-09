/// 资产组合概览
class PortfolioSummary {
  final double totalValueUsd;
  final double change24hUsd;
  final double change24hPercent;
  final int connectedExchanges;
  final int totalHoldings;

  const PortfolioSummary({
    required this.totalValueUsd,
    required this.change24hUsd,
    required this.change24hPercent,
    required this.connectedExchanges,
    required this.totalHoldings,
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
