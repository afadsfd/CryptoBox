import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/exchanges/models/balance.dart';
import '../../core/market/coingecko_provider.dart';
import '../portfolio/models/exchange_holdings_group.dart';
import '../portfolio/models/portfolio_summary.dart';
import '../portfolio/portfolio_provider.dart';
import '../portfolio/portfolio_service.dart';

/// 单资产行（UI）
class DashboardAssetRow {
  final String symbol;
  final String name;
  final double quantity;
  final double priceUsd;
  final double valueUsd;
  final double change24hPercent;
  /// 占该交易所小计的比例
  final double pctOfExchange;
  /// 占组合总资产的比例
  final double pctOfPortfolio;
  final String? imageUrl;
  final String iconLetter;
  final int iconColor;

  const DashboardAssetRow({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.priceUsd,
    required this.valueUsd,
    required this.change24hPercent,
    required this.pctOfExchange,
    required this.pctOfPortfolio,
    this.imageUrl,
    required this.iconLetter,
    required this.iconColor,
  });
}

/// 按来源拆分的子分组
class DashboardSourceSubSection {
  final BalanceSource source;
  final String label; // 现货 / 资金账户 / U本位合约等
  final double totalValueUsd;
  final double pctOfExchange;
  final List<DashboardAssetRow> assets;

  const DashboardSourceSubSection({
    required this.source,
    required this.label,
    required this.totalValueUsd,
    required this.pctOfExchange,
    required this.assets,
  });
}

/// 按交易所账户分组（可展开）
class DashboardExchangeSection {
  final String accountId;
  final String headerLabel;
  final String exchangeId;
  final String displayName;
  final String? exchangeLogoUrl;
  final DateTime? lastSyncAt;
  final double totalValueUsd;
  final double pctOfPortfolio;
  final List<DashboardAssetRow> assets;
  final List<BalanceSource> supportedSources;

  /// 按来源拆分的子分组（可能为空，仅含一个，或多个）
  final List<DashboardSourceSubSection> sourceSections;

  const DashboardExchangeSection({
    required this.accountId,
    required this.headerLabel,
    required this.exchangeId,
    required this.displayName,
    this.exchangeLogoUrl,
    this.lastSyncAt,
    required this.totalValueUsd,
    required this.pctOfPortfolio,
    required this.assets,
    this.supportedSources = const [],
    this.sourceSections = const [],
  });
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
  final String? logoUrl;
  final String exchangeId;

  SourceDistribution({
    required this.source,
    required this.value,
    required this.percent,
    this.logoUrl,
    this.exchangeId = '',
  });
}

/// Dashboard 状态
class DashboardState {
  final double totalValue;
  final double change24h;
  final double changePercent;
  final List<DashboardExchangeSection> exchangeSections;
  final ChartData chartData;
  final List<ConnectedSource> connectedSources;
  final List<SourceDistribution> sourceDistribution;
  final bool isLoading;
  final bool hasLoadedOnce;
  final String? error;
  final String selectedPeriod;
  final List<PortfolioWarning> warnings;

  DashboardState({
    this.totalValue = 0.0,
    this.change24h = 0.0,
    this.changePercent = 0.0,
    this.exchangeSections = const [],
    required this.chartData,
    this.connectedSources = const [],
    this.sourceDistribution = const [],
    this.isLoading = false,
    this.hasLoadedOnce = false,
    this.error,
    this.selectedPeriod = '1M',
    this.warnings = const [],
  });

  bool get hasAnyData =>
      totalValue > 0 ||
      exchangeSections.isNotEmpty ||
      chartData.points.isNotEmpty;

  DashboardState copyWith({
    double? totalValue,
    double? change24h,
    double? changePercent,
    List<DashboardExchangeSection>? exchangeSections,
    ChartData? chartData,
    List<ConnectedSource>? connectedSources,
    List<SourceDistribution>? sourceDistribution,
    bool? isLoading,
    bool? hasLoadedOnce,
    Object? error = _sentinel,
    String? selectedPeriod,
    List<PortfolioWarning>? warnings,
  }) {
    return DashboardState(
      totalValue: totalValue ?? this.totalValue,
      change24h: change24h ?? this.change24h,
      changePercent: changePercent ?? this.changePercent,
      exchangeSections: exchangeSections ?? this.exchangeSections,
      chartData: chartData ?? this.chartData,
      connectedSources: connectedSources ?? this.connectedSources,
      sourceDistribution: sourceDistribution ?? this.sourceDistribution,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      error: identical(error, _sentinel) ? this.error : error as String?,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      warnings: warnings ?? this.warnings,
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

  /// 两阶段加载：
  ///  Phase 1 — 纯 DB 缓存读取，秒渲染上次数据
  ///  Phase 2 — 后台网络同步，完成后自动刷新 UI
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    // ─── Phase 1: 从本地 DB 秒出 ───
    try {
      await Future.wait([
        _loadSummaryFromCache(),
        _loadHistory(state.selectedPeriod),
        _loadHoldings(),
        _loadSources(),
      ]);
    } catch (e) {
      debugPrint('Dashboard: cache load failed: $e');
    }

    // 缓存数据就绪 → 立即渲染，不再 loading
    state = state.copyWith(
      isLoading: false,
      hasLoadedOnce: true,
    );

    // ─── Phase 2: 后台静默网络同步 ───
    _backgroundSync();
  }

  /// 后台同步：拉取网络数据 → 写 DB → 刷新 UI（不 block 用户交互）
  Future<void> _backgroundSync() async {
    try {
      // 网络拉取 + 写 DB
      await _loadSummary();

      // 同步完成，用最新数据再刷一次 holdings / sources（含图片拉取）
      await Future.wait([
        _loadHoldings(fetchImages: true),
        _loadSources(),
      ]);
    } catch (e) {
      debugPrint('Dashboard: background sync failed: $e');
      // 静默失败，用户已经看到缓存数据了
    }
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

  /// 纯 DB 读取摘要（不发网络请求）
  Future<void> _loadSummaryFromCache() async {
    final summary = await _portfolioService.getPortfolioSummaryFromCache();
    state = state.copyWith(
      totalValue: summary.totalValueUsd,
      change24h: summary.change24hUsd,
      changePercent: summary.change24hPercent,
    );
  }

  /// 网络拉取最新余额 + 价格 → 写入 DB → 更新 state
  Future<void> _loadSummary() async {
    final summary = await _portfolioService.getPortfolioSummary();
    state = state.copyWith(
      totalValue: summary.totalValueUsd,
      change24h: summary.change24hUsd,
      changePercent: summary.change24hPercent,
      warnings: summary.warnings,
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

  Future<void> _loadHoldings({bool fetchImages = false}) async {
    final groups = await _portfolioService.getHoldingsGroupedByExchange();
    final grandTotal =
        groups.fold<double>(0, (sum, g) => sum + g.totalValueUsd);

    final allSymbols = <String>{};
    for (final g in groups) {
      for (final a in g.holdings) {
        allSymbols.add(a.symbol);
      }
    }

    // 图片：fetchImages=false 时用内存缓存（不发网络请求）
    Map<String, String> images = {};
    if (allSymbols.isNotEmpty) {
      try {
        final cg = _ref.read(coingeckoServiceProvider);
        if (fetchImages) {
          images = await cg.getCoinSmallImageUrls(allSymbols.toList());
        } else {
          // 仅读取内存缓存中已有的图片 URL
          images = cg.getCachedImageUrls(allSymbols.toList());
        }
      } catch (e) {
        debugPrint('Dashboard: coin images failed: $e');
      }
    }

    final sections = _buildSections(groups, grandTotal, images);
    state = state.copyWith(exchangeSections: sections);
  }

  List<DashboardExchangeSection> _buildSections(
    List<ExchangeHoldingsGroup> groups,
    double grandTotal,
    Map<String, String> images,
  ) {
    DashboardAssetRow rowFor(
      AccountHoldingLine a,
      double exchangeTotal,
    ) {
      final sym = a.symbol;
      final pctEx = exchangeTotal > 0 ? a.valueUsd / exchangeTotal * 100 : 0.0;
      final pctPort = grandTotal > 0 ? a.valueUsd / grandTotal * 100 : 0.0;
      return DashboardAssetRow(
        symbol: sym,
        name: sym,
        quantity: a.quantity,
        priceUsd: a.priceUsd,
        valueUsd: a.valueUsd,
        change24hPercent: a.change24h ?? 0.0,
        pctOfExchange: pctEx,
        pctOfPortfolio: pctPort,
        imageUrl: images[sym],
        iconLetter: sym.isNotEmpty ? sym[0] : '?',
        iconColor: _coinColorMap[sym] ?? _defaultCoinColor,
      );
    }

    return groups.map((g) {
      final rows = g.holdings.map((a) => rowFor(a, g.totalValueUsd)).toList();

      final subs = g.sourceGroups.map((sg) {
        final subAssets =
            sg.holdings.map((a) => rowFor(a, g.totalValueUsd)).toList();
        return DashboardSourceSubSection(
          source: sg.source,
          label: sg.source.label,
          totalValueUsd: sg.totalValueUsd,
          pctOfExchange: g.totalValueUsd > 0
              ? sg.totalValueUsd / g.totalValueUsd * 100
              : 0.0,
          assets: subAssets,
        );
      }).toList();

      return DashboardExchangeSection(
        accountId: g.accountId,
        headerLabel: g.label,
        exchangeId: g.exchangeId,
        displayName: g.displayName,
        exchangeLogoUrl: g.logoUrl.isEmpty ? null : g.logoUrl,
        lastSyncAt: g.lastSyncAt,
        totalValueUsd: g.totalValueUsd,
        pctOfPortfolio:
            grandTotal > 0 ? g.totalValueUsd / grandTotal * 100 : 0.0,
        assets: rows,
        supportedSources: g.supportedSources,
        sourceSections: subs,
      );
    }).toList();
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
                logoUrl: s.logoUrl.isEmpty ? null : s.logoUrl,
                exchangeId: s.exchangeName,
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

  /// 手动刷新：显示 loading → 网络同步 → 刷新 UI
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    String? criticalError;
    try {
      await _loadSummary();
    } catch (e) {
      debugPrint('Dashboard: refresh summary failed: $e');
      criticalError = _humanizeError(e);
    }

    try {
      await Future.wait([
        _loadHistory(state.selectedPeriod),
        _loadHoldings(fetchImages: true),
        _loadSources(),
      ]);
    } catch (e) {
      debugPrint('Dashboard: refresh secondary data failed: $e');
      criticalError ??= _humanizeError(e);
    }

    state = state.copyWith(
      isLoading: false,
      hasLoadedOnce: true,
      error: criticalError,
    );
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
