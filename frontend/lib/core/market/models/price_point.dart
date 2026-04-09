/// 价格数据点，用于历史价格图表
class PricePoint {
  final DateTime timestamp;
  final double price;

  const PricePoint({required this.timestamp, required this.price});

  @override
  String toString() => 'PricePoint(${timestamp.toIso8601String()}, $price)';
}
