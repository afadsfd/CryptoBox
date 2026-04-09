import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../portfolio/portfolio_provider.dart';
import '../portfolio/portfolio_service.dart';

/// 持仓数据模型（UI 层使用）
class HoldingItem {
  final String symbol;
  final String name;
  final double quantity;
  final double priceUsd;
  final double valueUsd;
  final double change24hPercent;
  final double portfolioPercent;
  final String iconLetter;
  final int iconColor;

  HoldingItem({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.priceUsd,
    required this.valueUsd,
    required this.change24hPercent,
    required this.portfolioPercent,
    required this.iconLetter,
    required this.iconColor,
  });

  HoldingItem copyWith({
    String? symbol,
    String? name,
    double? quantity,
    double? priceUsd,
    double? valueUsd,
    double? change24hPercent,
    double? portfolioPercent,
    String? iconLetter,
    int? iconColor,
  }) {
    return HoldingItem(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      priceUsd: priceUsd ?? this.priceUsd,
      valueUsd: valueUsd ?? this.valueUsd,
      change24hPercent: change24hPercent ?? this.change24hPercent,
      portfolioPercent: portfolioPercent ?? this.portfolioPercent,
      iconLetter: iconLetter ?? this.iconLetter,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}

/// 图表数据点
class ChartDataPoint {
  final DateTime timestamp;
  final double value;

  ChartDataPoint({
    required this.timestamp,
    required this.value,
  });
}

/// 图表数据
class ChartData {
  final List<ChartDataPoint> points;
  final double high;
  final double low;
  final double average;

  ChartData({
    required this.points,
    required this.high,
    required this.low,
    required this.average,
  });
}

/// 已连接数据源（UI 层使用）
class ConnectedSource {
  final String id;
  final String name;
  final String type; // 'api'
  final String? exchange;
  final String? chain;
  final String status; // 'active' | 'inactive'
  final DateTime lastSync;

  ConnectedSource({
    required this.id,
    required this.name,
    required this.type,
    this.exchange,
    this.chain,
    required this.status,
    required this.lastSync,
  });
}

/// 交易所分布
class SourceDistribution {
  final String source;
  final double value;
  final double percent;

  SourceDistribution({
    required this.source,
    required this.value,
    required this.percent,
  });
}

/// Dashboard 状态
class DashboardState {
  final double totalValue;
  final double change24h;
  final double changePercent;
  final List<HoldingItem> holdings;
  final ChartData chartData;
  final List<ConnectedSource> connectedSources;
  final List<SourceDistribution> sourceDistribution;
  final bool isLoading;
  final bool hasLoadedOnce;
  final String? error;
  final String selectedPeriod;

  DashboardState({
    this.totalValue = 0.0,
    this.change24h = 0.0,
    this.changePercent = 0.0,
    this.holdings = const [],
    required this.chartData,
    this.connectedSources = const [],
    this.sourceDistribution = const [],
    this.isLoading = false,
    this.hasLoadedOnce = false,
    this.error,
    this.selectedPeriod = '1M',
  });

  bool get hasAnyData =>
      totalValue > 0 || holdings.isNotEmpty || chartData.points.isNotEmpty;

  DashboardState copyWith({
    double? totalValue,
    double? change24h,
    double? changePercent,
    List<HoldingItem>? holdings,
    ChartData? chartData,
    List<ConnectedSource>? connectedSources,
    List<SourceDistribution>? sourceDistribution,
    bool? isLoading,
    bool? hasLoadedOnce,
    Object? error = _sentinel,
    String? selectedPeriod,
  }) {
    return DashboardState(
      totalValue: totalValue ?? this.totalValue,
      change24h: change24h ?? this.change24h,
      changePercent: changePercent ?? this.changePercent,
      holdings: holdings ?? this.holdings,
      chartData: chartData ?? this.chartData,
      connectedSources: connectedSources ?? this.connectedSources,
      sourceDistribution: sourceDistribution ?? this.sourceDistribution,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      error: identical(error, _sentinel) ? this.error : error as String?,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

const _sentinel = Object();

/// Dashboard Notifier — 所有数据通过本地 PortfolioService 获取
class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;
  late final PortfolioService _portfolioService;

  static const Map<String, int> _coinColorMap = {
    'BTC': 0xFFF7931A,
    'ETH': 0xFF627EEA,
    'SOL': 0xFF14F195,
    'BNB': 0xFFF3BA2F,
  };

  static const int _defaultCoinColor = 0xFF3B82F6;

  /// UI 周期 → PortfolioService 周期
  static const Map<String, String> _periodServiceMap = {
    '1D': '7d', // 本地最小粒度 7d
    '1W': '7d',
    '1M': '30d',
    '3M': '90d',
    'All': '90d',
  };

  DashboardNotifier(this._ref)
      : super(DashboardState(
          chartData: ChartData(points: [], high: 0, low: 0, average: 0),
        )) {
    _portfolioService = _ref.read(portfolioServiceProvider);
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    String? criticalError;

    await Future.wait([
      _loadSummary().catchError((Object e) {
        debugPrint('Dashboard: summary load failed: $e');
        criticalError ??= _humanizeError(e);
      }),
      _loadHistory(state.selectedPeriod),
      _loadHoldings().catchError((Object e) {
        debugPrint('Dashboard: holdings load failed: $e');
        criticalError ??= _humanizeError(e);
      }),
      _loadSources(),
    ]);

    state = state.copyWith(
      isLoading: false,
      hasLoadedOnce: true,
      error: criticalError,
    );
  }

  String _humanizeError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection')) {
      return 'Network unavailable. Check your connection.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Unable to load data. Please try again.';
  }

  Future<void> _loadSummary() async {
    final summary = await _portfolioService.getPortfolioSummary();

    state = state.copyWith(
      totalValue: summary.totalValueUsd,
      change24h: summary.change24hUsd,
      changePercent: summary.change24hPercent,
    );
  }

  Future<void> _loadHistory(String period) async {
    try {
      final servicePeriod = _periodServiceMap[period] ?? '30d';
      final historyPoints =
          await _portfolioService.getPortfolioHistory(servicePeriod);

      if (state.selectedPeriod != period) return;

      final points = historyPoints
          .map((p) => ChartDataPoint(
                timestamp: p.timestamp,
                value: p.totalValue,
              ))
          .toList();

      double high = 0, low = double.infinity, sum = 0;
      for (final p in points) {
        if (p.value > high) high = p.value;
        if (p.value < low) low = p.value;
        sum += p.value;
      }
      if (points.isEmpty) {
        low = 0;
      }
      final average = points.isNotEmpty ? sum / points.length : 0.0;

      state = state.copyWith(
        chartData: ChartData(
          points: points,
          high: high,
          low: low,
          average: average,
        ),
      );
    } catch (e) {
      debugPrint('Failed to load portfolio history: $e');
    }
  }

  Future<void> _loadHoldings() async {
    final items = await _portfolioService.getHoldings();

    // 计算总值用于百分比
    double totalVal = 0;
    for (final h in items) {
      totalVal += h.valueUsd;
    }

    final holdings = items.map((h) {
      final symbol = h.symbol;
      return HoldingItem(
        symbol: symbol,
        name: symbol, // 本地服务无 name 字段，使用 symbol
        quantity: h.quantity,
        priceUsd: h.priceUsd,
        valueUsd: h.valueUsd,
        change24hPercent: h.change24h ?? 0.0,
        portfolioPercent:
            totalVal > 0 ? h.valueUsd / totalVal * 100 : 0.0,
        iconLetter: symbol.isNotEmpty ? symbol[0] : '?',
        iconColor: _coinColorMap[symbol] ?? _defaultCoinColor,
      );
    }).toList();

    state = state.copyWith(holdings: holdings);
  }

  Future<void> _loadSources() async {
    try {
      final sources = await _portfolioService.getConnectedSources();

      final connectedSources = sources.map((s) {
        return ConnectedSource(
          id: s.id,
          name: s.label,
          type: 'api',
          exchange: s.exchangeName,
          status: s.isActive ? 'active' : 'inactive',
          lastSync: s.lastSyncAt ?? DateTime.now(),
        );
      }).toList();

      // sourceDistribution 也在这里计算，避免重复调用
      final distributionList = sources
          .where((s) => s.totalValueUsd > 0)
          .map((s) => SourceDistribution(
                source: s.label,
                value: s.totalValueUsd,
                percent: s.percentage,
              ))
          .toList();

      state = state.copyWith(
        connectedSources: connectedSources,
        sourceDistribution: distributionList,
      );
    } catch (e) {
      debugPrint('Failed to load connected sources: $e');
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadDashboard();
  }

  /// 切换时间周期
  Future<void> changePeriod(String period) async {
    if (state.selectedPeriod == period) return;

    state = state.copyWith(selectedPeriod: period);
    await _loadHistory(period);
  }

  /// 获取 FlSpot 列表用于图表
  List<FlSpot> getChartSpots() {
    final points = state.chartData.points;
    if (points.isEmpty) return [];

    return points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  /// 格式化金额
  String formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  /// 格式化大数字
  String formatLargeNumber(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '\$$intPart.${parts[1]}';
  }
}

/// Dashboard Provider
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});

/// 总资产 Provider（用于监听特定变化）
final totalValueProvider = Provider<double>((ref) {
  return ref.watch(dashboardProvider).totalValue;
});

/// 24h 涨跌幅 Provider
final changePercentProvider = Provider<double>((ref) {
  return ref.watch(dashboardProvider).changePercent;
});

/// 持仓列表 Provider
final holdingsProvider = Provider<List<HoldingItem>>((ref) {
  return ref.watch(dashboardProvider).holdings;
});

/// 图表数据 Provider
final chartDataProvider = Provider<ChartData>((ref) {
  return ref.watch(dashboardProvider).chartData;
});

/// 已连接数据源 Provider
final connectedSourcesProvider = Provider<List<ConnectedSource>>((ref) {
  return ref.watch(dashboardProvider).connectedSources;
});

/// 选中的时间周期 Provider
final selectedPeriodProvider = Provider<String>((ref) {
  return ref.watch(dashboardProvider).selectedPeriod;
});

/// 加载状态 Provider
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardProvider).isLoading;
});
