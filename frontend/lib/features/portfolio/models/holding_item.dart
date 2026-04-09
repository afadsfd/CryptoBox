import 'dart:ui';

/// 单个持仓项
class HoldingItem {
  final String symbol;
  final double quantity;
  final double priceUsd;
  final double valueUsd;
  final double? change24h;

  /// 如果是单交易所持仓，此字段为交易所名称
  final String? exchangeName;

  /// 图标颜色（UI 层使用）
  final Color? iconColor;

  const HoldingItem({
    required this.symbol,
    required this.quantity,
    required this.priceUsd,
    required this.valueUsd,
    this.change24h,
    this.exchangeName,
    this.iconColor,
  });

  /// 该持仓在总资产中的占比（由上层计算后设置）
  double percentOfTotal(double totalValue) {
    if (totalValue <= 0) return 0;
    return valueUsd / totalValue * 100;
  }
}
