import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/exchanges/models/balance.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/format_helper.dart';
import '../../shared/widgets/sharp_network_image.dart';
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
    final l10n = AppLocalizations.of(context);
    final err = ref.read(dashboardProvider).error;
    if (err == null) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(l10n.get('portfolio_updated')),
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
    final l10n = AppLocalizations.of(context);

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
                    l10n.get('top_holdings'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOnSurface,
                    ),
                  ),
                ),
              ),

              // 持仓列表 / 空状态
              if (state.exchangeSections.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: l10n.get('no_holdings_title'),
                      message: l10n.get('no_holdings_message'),
                      actionLabel: l10n.get('connect_exchange'),
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
                        final section = state.exchangeSections[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildExchangeHoldingsSection(
                            context,
                            section,
                            index == 0,
                          ),
                        );
                      },
                      childCount: state.exchangeSections.length,
                    ),
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
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 小标题
          Text(
            l10n.get('total_portfolio_value'),
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
                                Icon(changeIcon, size: 14, color: changeColor),
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
              _buildExchangeAvatars(state),
            ],
          ),
        ],
      ),
    );
  }

  static const _exchangeAvatarColors = {
    'binance': Color(0xFFF3BA2F),
    'okx': Color(0xFFFFFFFF),
    'bybit': Color(0xFFF7A600),
    'coinbase': Color(0xFF0052FF),
    'gateio': Color(0xFF2354E6),
    'bitget': Color(0xFF00F0FF),
  };

  Widget _buildExchangeAvatars(DashboardState state) {
    final sources = state.sourceDistribution.take(3).toList();
    final totalAvatars =
        sources.length + (state.sourceDistribution.length > 3 ? 1 : 0);
    final totalWidth =
        totalAvatars > 0 ? 36.0 + (totalAvatars - 1) * 28.0 : 0.0;

    Widget avatarFace(SourceDistribution src, Color ringColor) {
      final letter = src.source.isNotEmpty ? src.source.substring(0, 1) : '?';
      final url = src.logoUrl;
      if (url != null && url.isNotEmpty) {
        return SharpNetworkImage(
          imageUrl: url,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(18),
          placeholder: (_, __) => Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ringColor,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ringColor,
              ),
            ),
          ),
        );
      }
      return Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ringColor,
          ),
        ),
      );
    }

    return SizedBox(
      width: totalWidth,
      height: 36,
      child: Stack(
        children: [
          ...sources.asMap().entries.map((entry) {
            final id = entry.value.exchangeId.toLowerCase();
            final color =
                _exchangeAvatarColors[id] ?? AppTheme.primaryContainer;
            return Positioned(
              left: entry.key * 28.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(77),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: avatarFace(entry.value, color),
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
                  border: Border.all(color: AppTheme.background, width: 2),
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.get('growth_metrics'),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.get('performance_analysis'),
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
                _buildStatItem(l10n.get('high'), notifier.formatCurrency(state.chartData.high)),
                _buildStatItem(l10n.get('low'), notifier.formatCurrency(state.chartData.low)),
                _buildStatItem(l10n.get('average'), notifier.formatCurrency(state.chartData.average)),
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

  /// 按交易所分组的展开卡片
  Widget _buildExchangeHoldingsSection(
    BuildContext context,
    DashboardExchangeSection section,
    bool isPrimary,
  ) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: isPrimary ? AppTheme.primaryContainer.withAlpha(77) : null,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            initiallyExpanded: isPrimary,
            iconColor: AppTheme.textOnSurfaceVariant,
            collapsedIconColor: AppTheme.textOnSurfaceVariant,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            leading: _buildRoundExchangeLogo(
              section.exchangeLogoUrl,
              section.displayName,
              section.exchangeId,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FormatHelper.currency(section.totalValueUsd),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryContainer,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${section.pctOfPortfolio.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textOnSurfaceVariant,
                  ),
                ),
              ],
            ),
            children: _buildSectionChildren(section),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionChildren(DashboardExchangeSection section) {
    // 只有一个来源（或没有子分组）时，直接渲染资产行，保持原有紧凑布局
    if (section.sourceSections.length <= 1) {
      return section.assets.map(_buildAssetRow).toList();
    }

    final widgets = <Widget>[];
    for (final sub in section.sourceSections) {
      widgets.add(_buildSourceHeader(sub));
      widgets.addAll(sub.assets.map(_buildAssetRow));
    }
    return widgets;
  }

  Widget _buildSourceHeader(DashboardSourceSubSection sub) {
    final color = _sourceColor(sub.source);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withAlpha(90), width: 0.7),
            ),
            child: Text(
              sub.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              FormatHelper.currency(sub.totalValueUsd),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textOnSurface,
              ),
            ),
          ),
          Text(
            '${sub.pctOfExchange.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _sourceColor(BalanceSource s) {
    switch (s) {
      case BalanceSource.spot:
        return AppTheme.accentCyan;
      case BalanceSource.earn:
        return const Color(0xFF22C55E); // green
      case BalanceSource.futures:
        return const Color(0xFFF59E0B); // amber
    }
  }

  Widget _buildRoundExchangeLogo(
    String? logoUrl,
    String displayName,
    String exchangeId,
  ) {
    const size = 36.0;
    final id = exchangeId.toLowerCase();
    final ring = _exchangeAvatarColors[id] ?? AppTheme.accentCyan;
    final letter =
        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return SharpNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(size / 2),
        placeholder: (_, __) => _letterAvatar(size, letter, ring),
        errorWidget: (_, __, ___) => _letterAvatar(size, letter, ring),
      );
    }
    return _letterAvatar(size, letter, ring);
  }

  Widget _letterAvatar(double size, String letter, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /// 单资产行（全额金额 + 可选网络图标）
  Widget _buildAssetRow(DashboardAssetRow row) {
    final isPositive = row.change24hPercent >= 0;
    const iconSize = 36.0;

    Widget coinFace() {
      final url = row.imageUrl;
      if (url != null && url.isNotEmpty) {
        return SharpNetworkImage(
          imageUrl: url,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(10),
          placeholder: (_, __) => _fallbackCoinIcon(row),
          errorWidget: (_, __, ___) => _fallbackCoinIcon(row),
        );
      }
      return _fallbackCoinIcon(row);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: iconSize, height: iconSize, child: coinFace()),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOnSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isPositive ? '+' : ''}${row.change24hPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatHelper.currency(row.valueUsd),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryContainer,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.pctOfExchange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCoinIcon(DashboardAssetRow row) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Color(row.iconColor).withAlpha(38),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        row.iconLetter,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(row.iconColor),
        ),
      ),
    );
  }

}
