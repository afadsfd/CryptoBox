import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/utils/format_helper.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/skeleton.dart';
import '../profile/profile_provider.dart';
import 'dashboard_provider.dart';

/// 首页资产看板 (Dashboard)
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _scheduleAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    final interval = ref.read(userPreferencesProvider).refreshIntervalMinutes;
    if (interval <= 0) return;
    _autoRefreshTimer = Timer.periodic(
      Duration(minutes: interval),
      (_) {
        if (mounted) {
          ref.read(dashboardProvider.notifier).refresh();
        }
      },
    );
  }

  Future<void> _manualRefresh() async {
    HapticFeedback.lightImpact();
    await ref.read(dashboardProvider.notifier).refresh();
    if (!mounted) return;
    final err = ref.read(dashboardProvider).error;
    if (err == null) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Portfolio updated'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(milliseconds: 1500),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听刷新间隔变化
    ref.listen(
      userPreferencesProvider.select((p) => p.refreshIntervalMinutes),
      (_, __) => _scheduleAutoRefresh(),
    );

    final state = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    // 首次加载中 - 展示骨架屏
    if (state.isLoading && !state.hasLoadedOnce) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: const DashboardSkeleton(),
        ),
      );
    }

    // 首次加载失败 - 展示错误页
    if (state.error != null && !state.hasAnyData) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: ErrorStateView(
              message: state.error!,
              onRetry: () => notifier.refresh(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        color: AppTheme.primaryContainer,
        backgroundColor: AppTheme.surface,
        displacement: 20,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 顶部总资产区域
              SliverToBoxAdapter(
                child: _buildTotalPortfolioSection(context, state, notifier),
              ),

              // Growth Metrics 趋势图
              SliverToBoxAdapter(
                child: _buildGrowthMetricsSection(context, state, notifier),
              ),

              // Top Holdings 标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    'Top Holdings',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOnSurface,
                    ),
                  ),
                ),
              ),

              // 持仓列表 / 空状态
              if (state.holdings.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No holdings yet',
                      message:
                          'Connect an exchange or wallet to start tracking your portfolio.',
                      actionLabel: 'Connect Exchange',
                      onAction: () => context.goConnect(),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final holding = state.holdings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              _buildHoldingCard(context, holding, index == 0),
                        );
                      },
                      childCount: state.holdings.length,
                    ),
                  ),
                ),

              // Connected Nodes 卡片（仅在有数据源时显示）
              if (state.connectedSources.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildConnectedNodesCard(context, state),
                  ),
                ),

              // 底部留白
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部总资产区域
  Widget _buildTotalPortfolioSection(
    BuildContext context,
    DashboardState state,
    DashboardNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 小标题
          Text(
            'Total Portfolio Value',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总资产金额
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FormatHelper.currency(state.totalValue),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 涨跌标签行
                    Builder(builder: (context) {
                      final isPositive = state.changePercent >= 0;
                      final changeColor =
                          isPositive ? AppTheme.success : AppTheme.danger;
                      final changeIcon = isPositive
                          ? Icons.trending_up
                          : Icons.trending_down;
                      final sign = isPositive ? '+' : '';

                      return Row(
                        children: [
                          // 百分比标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: changeColor.withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  changeIcon,
                                  size: 14,
                                  color: changeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$sign${state.changePercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: changeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 涨跌金额
                          Text(
                            '$sign${FormatHelper.currency(state.change24h)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: changeColor,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              
              // 已连接交易所图标行
              _buildExchangeAvatars(state),
            ],
          ),
        ],
      ),
    );
  }

  /// 交易所头像行
  Widget _buildExchangeAvatars(DashboardState state) {
    final sources = state.sourceDistribution.take(3).toList();
    final totalAvatars = sources.length + (state.sourceDistribution.length > 3 ? 1 : 0);
    // 每个头像 36px 宽，重叠偏移 8px
    final totalWidth = totalAvatars > 0 ? 36.0 + (totalAvatars - 1) * 28.0 : 0.0;

    return SizedBox(
      width: totalWidth,
      height: 36,
      child: Stack(
        children: [
          ...sources.asMap().entries.map((entry) {
            final colors = {
              'Binance': const Color(0xFFF3BA2F),
              'Coinbase': const Color(0xFF0052FF),
              'Kraken': const Color(0xFF5741D9),
              'Wallet-ETH': const Color(0xFF627EEA),
            };
            final color = colors[entry.value.source] ?? AppTheme.primaryContainer;

            return Positioned(
              left: entry.key * 28.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.background,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(77),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    entry.value.source.isNotEmpty
                        ? entry.value.source.substring(0, 1)
                        : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (state.sourceDistribution.length > 3)
            Positioned(
              left: sources.length * 28.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.background,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+${state.sourceDistribution.length - 3}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Growth Metrics 趋势图区域
  Widget _buildGrowthMetricsSection(
    BuildContext context,
    DashboardState state,
    DashboardNotifier notifier,
  ) {
    final periods = ['1D', '1W', '1M', '3M', 'All'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth Metrics',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '30-Day Performance Analysis',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textOnSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 时间切换按钮组
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: periods.map((period) {
                  final isSelected = state.selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => notifier.changePeriod(period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryContainer
                              : AppTheme.surfaceHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.onPrimaryContainer
                                : AppTheme.textOnSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            
            // 面积图
            SizedBox(
              height: 180,
              child: _buildAreaChart(state, notifier),
            ),
            
            const SizedBox(height: 16),
            
            // 底部统计行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('High', notifier.formatCurrency(state.chartData.high)),
                _buildStatItem('Low', notifier.formatCurrency(state.chartData.low)),
                _buildStatItem('Average', notifier.formatCurrency(state.chartData.average)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 统计项
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textOnSurface,
          ),
        ),
      ],
    );
  }

  /// 面积图
  Widget _buildAreaChart(DashboardState state, DashboardNotifier notifier) {
    final spots = notifier.getChartSpots();
    if (spots.isEmpty) return const SizedBox.shrink();

    final minY = state.chartData.low * 0.98;
    final maxY = state.chartData.high * 1.02;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppTheme.surfaceHighest,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final points = state.chartData.points;
                final value = spot.y;
                final dateStr = (idx >= 0 && idx < points.length)
                    ? DateFormat('MM/dd').format(points[idx].timestamp)
                    : '';
                return LineTooltipItem(
                  '\$${value.toStringAsFixed(2)}',
                  const TextStyle(
                    color: AppTheme.textOnSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    if (dateStr.isNotEmpty)
                      TextSpan(
                        text: '\n$dateStr',
                        style: TextStyle(
                          color: AppTheme.textOnSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // 渐变填充区域
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            barWidth: 0,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.success.withAlpha(77),
                  AppTheme.success.withAlpha(0),
                ],
              ),
            ),
          ),
          // 线条
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.success,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isLast = index == spots.length - 1;
                return FlDotCirclePainter(
                  radius: isLast ? 6 : 0,
                  color: AppTheme.success,
                  strokeWidth: 2,
                  strokeColor: AppTheme.background,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 持仓卡片
  Widget _buildHoldingCard(BuildContext context, HoldingItem holding, bool isPrimary) {
    final isPositive = holding.change24hPercent >= 0;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderColor: isPrimary ? AppTheme.primaryContainer.withAlpha(77) : null,
      onTap: () {},
      child: Row(
        children: [
          // 币种图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(holding.iconColor).withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                holding.iconLetter,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(holding.iconColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 名称和代码
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOnSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${isPositive ? '+' : ''}${holding.change24hPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isPositive ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
          ),

          // 持仓市值和占比
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatHelper.currencyCompact(holding.valueUsd),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppTheme.primary : AppTheme.textOnSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${holding.portfolioPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Connected Nodes 卡片
  Widget _buildConnectedNodesCard(BuildContext context, DashboardState state) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connected Nodes',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...state.connectedSources.take(2).map((source) {
            final isActive = source.status == 'active';
            final icon = source.type == 'api' ? Icons.wifi : Icons.cloud_done;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isActive ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textOnSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${source.type.toUpperCase()} · synced ${FormatHelper.relativeTime(source.lastSync)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.success : AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Syncing',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
