import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/empty_state.dart';
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
    final state = ref.watch(exchangesProvider);
    final notifier = ref.read(exchangesProvider.notifier);

    // 首次加载 - 骨架屏
    if (state.isLoading && !state.hasLoadedOnce) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(),
        body: const SafeArea(child: ExchangesSkeleton()),
      );
    }

    // 加载失败 - 错误页
    if (state.error != null && state.exchanges.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(),
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
      appBar: _buildAppBar(),
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
                      child: _buildSearchBar(notifier),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFilterChips(state, notifier),
                    ),
                  ),
                  if (state.activeConnectedExchanges.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Connected (${state.activeConnectedExchanges.length})',
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
                              connected, notifier);
                        },
                        childCount: state.activeConnectedExchanges.length,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Available Exchanges',
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
                            ? 'No exchanges found'
                            : 'No exchanges available',
                        message: state.searchQuery.isNotEmpty
                            ? 'Try a different search term or clear filters.'
                            : 'Pull down to refresh and try again.',
                        actionLabel: state.searchQuery.isNotEmpty
                            ? 'Clear search'
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
                          return _buildExchangeCard(exchange, isConnected);
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Connect Exchanges',
        style: GoogleFonts.spaceGrotesk(
          color: AppTheme.textOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar(ExchangesNotifier notifier) {
    return TextField(
      controller: _searchController,
      onChanged: notifier.setSearchQuery,
      style: const TextStyle(color: AppTheme.textOnSurface),
      decoration: InputDecoration(
        hintText: 'Search exchanges...',
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

  Widget _buildFilterChips(ExchangesState state, ExchangesNotifier notifier) {
    final filters = ['all', 'exchanges', 'wallets'];
    final labels = {'all': 'All', 'exchanges': 'Exchanges', 'wallets': 'Wallets'};

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
      ConnectedExchange connected, ExchangesNotifier notifier) {
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
          leading: CircleAvatar(
            backgroundColor: AppTheme.accentCyan.withAlpha(51),
            child: Text(
              connected.exchangeName.isNotEmpty
                  ? connected.exchangeName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppTheme.accentCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            connected.label,
            style: GoogleFonts.inter(
              color: AppTheme.textOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            connected.syncStatus == 'success' ? 'Synced' : connected.syncStatus,
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
                    title: const Text('Disconnect Exchange',
                        style: TextStyle(color: AppTheme.textOnSurface)),
                    content: Text(
                      'Are you sure you want to disconnect ${connected.label}?',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error),
                        child: const Text('Disconnect'),
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
              const PopupMenuItem(
                value: 'disconnect',
                child: Text('Disconnect',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeCard(Exchange exchange, bool isConnected) {
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
          leading: CircleAvatar(
            backgroundColor: _parseColor(exchange.logoColor).withAlpha(51),
            child: Text(
              exchange.logoLetter,
              style: TextStyle(
                color: _parseColor(exchange.logoColor),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            exchange.name,
            style: GoogleFonts.inter(
              color: AppTheme.textOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            exchange.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
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
                  child: const Text('Connect'),
                ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final hexClean = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexClean', radix: 16));
    } catch (_) {
      return AppTheme.accentCyan;
    }
  }
}
