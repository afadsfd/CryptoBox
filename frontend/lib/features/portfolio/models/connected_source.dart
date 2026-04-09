/// 已连接数据源
class ConnectedSource {
  final String id;
  final String exchangeName;
  final String label;
  final double totalValueUsd;
  final double percentage;
  final DateTime? lastSyncAt;
  final bool isActive;
  final String logoUrl;

  const ConnectedSource({
    required this.id,
    required this.exchangeName,
    required this.label,
    required this.totalValueUsd,
    required this.percentage,
    this.lastSyncAt,
    required this.isActive,
    this.logoUrl = '',
  });
}
