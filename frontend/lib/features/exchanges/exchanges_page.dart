import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/exchanges/models/balance.dart';
import '../../core/exchanges/models/exchange_info.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/sharp_network_image.dart';
import '../../shared/widgets/skeleton.dart';
import 'exchanges_provider.dart';

class ExchangesPage extends ConsumerStatefulWidget {
  const ExchangesPage({super.key});

  @override
  ConsumerState<ExchangesPage> createState() => _ExchangesPageState();
}

class _ExchangesPageState extends ConsumerState<ExchangesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(exchangesProvider);
    final notifier = ref.read(exchangesProvider.notifier);

    // 首次加载 - 骨架屏
    if (state.isLoading && !state.hasLoadedOnce) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(l10n),
        body: const SafeArea(child: ExchangesSkeleton()),
      );
    }

    // 加载失败 - 错误页
    if (state.error != null && state.exchanges.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(l10n),
        body: SafeArea(
          child: Center(
            child: ErrorStateView(
              message: state.error!,
              onRetry: () => notifier.retry(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(l10n),
      body: RefreshIndicator(
              color: AppTheme.primaryContainer,
              backgroundColor: AppTheme.surface,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await notifier.refreshConnectedExchanges();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSearchBar(l10n, notifier),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFilterChips(l10n, state, notifier),
                    ),
                  ),
                  if (state.activeConnectedExchanges.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          '${l10n.get('exchanges_connected')} (${state.activeConnectedExchanges.length})',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textOnSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final connected =
                              state.activeConnectedExchanges[index];
                          return _buildConnectedExchangeCard(
                              l10n, connected, notifier);
                        },
                        childCount: state.activeConnectedExchanges.length,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        l10n.get('exchanges_available'),
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textOnSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (state.filteredExchanges.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: state.searchQuery.isNotEmpty
                            ? l10n.get('no_exchanges_found')
                            : l10n.get('no_exchanges_available'),
                        message: state.searchQuery.isNotEmpty
                            ? l10n.get('try_different_search')
                            : l10n.get('pull_to_refresh'),
                        actionLabel: state.searchQuery.isNotEmpty
                            ? l10n.get('clear_search')
                            : null,
                        onAction: state.searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              }
                            : null,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final exchange = state.filteredExchanges[index];
                          final isConnected = state.isConnected(exchange.id);
                          return _buildExchangeCard(l10n, exchange, isConnected);
                        },
                        childCount: state.filteredExchanges.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        l10n.get('exchanges_title'),
        style: GoogleFonts.spaceGrotesk(
          color: AppTheme.textOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, ExchangesNotifier notifier) {
    return TextField(
      controller: _searchController,
      onChanged: notifier.setSearchQuery,
      style: const TextStyle(color: AppTheme.textOnSurface),
      decoration: InputDecoration(
        hintText: l10n.get('search_exchanges'),
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n, ExchangesState state, ExchangesNotifier notifier) {
    final filters = ['all', 'exchanges', 'wallets'];
    final labels = {'all': l10n.get('all'), 'exchanges': l10n.get('exchanges'), 'wallets': l10n.get('wallets')};

    return Row(
      children: filters.map((filter) {
        final isSelected = state.selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            selected: isSelected,
            label: Text(labels[filter] ?? filter),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            selectedColor: AppTheme.accentCyan,
            backgroundColor: AppTheme.surface,
            onSelected: (_) => notifier.setFilter(filter),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConnectedExchangeCard(
      AppLocalizations l10n, ConnectedExchange connected, ExchangesNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentCyan.withAlpha(77)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildExchangeLogo(
            connected.logoUrl,
            connected.exchangeName,
            _exchangeColorMap[connected.exchangeName.toLowerCase()],
          ),
          title: Text(
            connected.label,
            style: GoogleFonts.inter(
              color: AppTheme.textOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            connected.syncStatus == 'success' ? l10n.get('synced') : connected.syncStatus,
            style: TextStyle(
              color: connected.syncStatus == 'success'
                  ? AppTheme.success
                  : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            color: AppTheme.surface,
            onSelected: (value) async {
              if (value == 'disconnect') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: Text(l10n.get('disconnect_exchange'),
                        style: const TextStyle(color: AppTheme.textOnSurface)),
                    content: Text(
                      '${l10n.get('disconnect_confirm')} ${connected.label}?',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.get('cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error),
                        child: Text(l10n.get('disconnect')),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await notifier.disconnectExchange(connected.id);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'disconnect',
                child: Text(l10n.get('disconnect'),
                    style: const TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeCard(
      AppLocalizations l10n, Exchange exchange, bool isConnected) {
    final info = ExchangeInfo.findById(exchange.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildExchangeLogo(
            exchange.logoUrl,
            exchange.name,
            exchange.logoColor,
          ),
          title: Text(
            exchange.name,
            style: GoogleFonts.inter(
              color: AppTheme.textOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: info == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: _buildSupportChips(info.visibleAssetSupport),
                ),
          trailing: isConnected
              ? const Icon(Icons.check_circle, color: AppTheme.success)
              : ElevatedButton(
                  onPressed: () => context.pushAddApi(exchange.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(l10n.get('connect')),
                ),
        ),
      ),
    );
  }

  static const _exchangeColorMap = {
    'binance': '#F3BA2F',
    'okx': '#FFFFFF',
    'bybit': '#F7A600',
    'coinbase': '#0052FF',
    'gateio': '#2354E6',
    'bitget': '#00F0FF',
  };

  Widget _buildSupportChips(List<ExchangeAssetSupport> support) {
    final available = support.where((s) => s.isAvailable).toList();
    if (available.isEmpty) {
      return Text(
        '仅基础账户',
        style: GoogleFonts.inter(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      );
    }
    final shown = available.take(4).toList();
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        ...shown.map(_buildSupportChip),
        if (available.length > shown.length)
          _buildTinyChip('+${available.length - shown.length}', AppTheme.surface),
      ],
    );
  }

  Widget _buildSupportChip(ExchangeAssetSupport support) {
    final color = _supportLevelColor(support.level);
    final suffix =
        support.level == AssetSupportLevel.stable ? '' : ' ${support.level.label}';
    return _buildTinyChip('${support.source.label}$suffix', color.withAlpha(33),
        textColor: color);
  }

  Widget _buildTinyChip(String text, Color background, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (textColor ?? AppTheme.textSecondary).withAlpha(80),
          width: 0.6,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: textColor ?? AppTheme.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }

  Color _supportLevelColor(AssetSupportLevel level) {
    switch (level) {
      case AssetSupportLevel.stable:
        return AppTheme.success;
      case AssetSupportLevel.beta:
        return AppTheme.accentCyan;
      case AssetSupportLevel.partial:
        return const Color(0xFFF59E0B);
      case AssetSupportLevel.planned:
        return AppTheme.textSecondary;
      case AssetSupportLevel.unsupported:
        return AppTheme.error;
    }
  }

  Widget _buildExchangeLogo(String? logoUrl, String name, String? colorHex, {double size = 40}) {
    final fallbackColor = _parseColor(colorHex);
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return SharpNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(size / 2),
        placeholder: (_, __) => CircleAvatar(
          radius: size / 2,
          backgroundColor: fallbackColor.withAlpha(51),
          child: Text(
            letter,
            style: TextStyle(
              color: fallbackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          backgroundColor: fallbackColor.withAlpha(51),
          child: Text(
            letter,
            style: TextStyle(
              color: fallbackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: fallbackColor.withAlpha(51),
      child: Text(letter,
          style:
              TextStyle(color: fallbackColor, fontWeight: FontWeight.bold)),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return AppTheme.accentCyan;
    try {
      final hexClean = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexClean', radix: 16));
    } catch (_) {
      return AppTheme.accentCyan;
    }
  }
}
