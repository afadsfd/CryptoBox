/// 历史数据点（用于资产趋势图）
class HistoryDataPoint {
  final DateTime timestamp;
  final double totalValue;

  const HistoryDataPoint({
    required this.timestamp,
    required this.totalValue,
  });
}
