import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exchanges/models/balance.dart';
import '../../core/exchanges/models/exchange_info.dart';
import '../../core/local_storage/database_provider.dart';
import '../../core/local_storage/repositories/exchange_repository.dart';
import '../../core/local_storage/repositories/holding_repository.dart';

/// 交易所数据模型（UI 层使用）
class Exchange {
  final String id;
  final String name;
  final String description;
  final String logoColor;
  final String logoLetter;
  final String logoUrl;
  final bool supportsSpot;
  final bool supportsFutures;
  final bool requiresPassphrase;
  final bool isFeatured;
  final String status;
  final String category;

  const Exchange({
    required this.id,
    required this.name,
    required this.description,
    required this.logoColor,
    required this.logoLetter,
    this.logoUrl = '',
    this.supportsSpot = true,
    this.supportsFutures = true,
    this.requiresPassphrase = false,
    this.isFeatured = false,
    this.status = 'available',
    this.category = 'exchange',
  });
}

/// 已连接交易所数据模型
class ConnectedExchange {
  final String id;
  final String exchangeName;
  final String label;
  final String logoUrl;
  final bool isActive;
  final DateTime? lastSyncAt;
  final String syncStatus;

  const ConnectedExchange({
    required this.id,
    required this.exchangeName,
    required this.label,
    this.logoUrl = '',
    this.isActive = true,
    this.lastSyncAt,
    this.syncStatus = 'pending',
  });
}

/// 交易所状态
class ExchangesState {
  final List<Exchange> exchanges;
  final List<ConnectedExchange> connectedExchanges;
  final String searchQuery;
  final String selectedFilter;
  final bool isLoading;
  final bool hasLoadedOnce;
  final String? error;

  const ExchangesState({
    this.exchanges = const [],
    this.connectedExchanges = const [],
    this.searchQuery = '',
    this.selectedFilter = 'all',
    this.isLoading = false,
    this.hasLoadedOnce = false,
    this.error,
  });

  ExchangesState copyWith({
    List<Exchange>? exchanges,
    List<ConnectedExchange>? connectedExchanges,
    String? searchQuery,
    String? selectedFilter,
    bool? isLoading,
    bool? hasLoadedOnce,
    Object? error = _sentinel,
  }) {
    return ExchangesState(
      exchanges: exchanges ?? this.exchanges,
      connectedExchanges: connectedExchanges ?? this.connectedExchanges,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  /// 获取已连接的活跃交易所列表
  List<ConnectedExchange> get activeConnectedExchanges {
    return connectedExchanges.where((e) => e.isActive).toList();
  }

  /// 获取筛选后的交易所列表
  List<Exchange> get filteredExchanges {
    return exchanges.where((exchange) {
      // 搜索过滤
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!exchange.name.toLowerCase().contains(query) &&
            !exchange.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 分类过滤
      if (selectedFilter != 'all') {
        if (selectedFilter == 'exchanges' && exchange.category != 'exchange') {
          return false;
        }
        if (selectedFilter == 'wallets' && exchange.category != 'wallet') {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 检查交易所是否已连接
  bool isConnected(String exchangeId) {
    return connectedExchanges.any(
      (e) => e.exchangeName == exchangeId && e.isActive,
    );
  }

  /// 按唯一 ID 查找已连接交易所
  ConnectedExchange? getConnectedExchangeById(String id) {
    for (final e in connectedExchanges) {
      if (e.id == id) return e;
    }
    return null;
  }
}

const _sentinel = Object();

/// 交易所颜色映射
const _exchangeColorMap = {
  'binance': '#F3BA2F',
  'okx': '#FFFFFF',
  'bybit': '#000000',
  'coinbase': '#0052FF',
  'gateio': '#2354E6',
  'bitget': '#00F0FF',
};

/// 交易所 Logo 字母映射
const _logoLetterMap = {
  'binance': 'B',
  'bybit': 'By',
  'okx': 'O',
  'coinbase': 'C',
  'gateio': 'G',
  'bitget': 'Bg',
};

String _computeLogoLetter(String name) {
  final key = name.toLowerCase();
  return _logoLetterMap[key] ??
      (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?');
}

/// 交易所状态 Notifier — 本地化版本
class ExchangesNotifier extends StateNotifier<ExchangesState> {
  final Ref _ref;

  ExchangesNotifier(this._ref) : super(const ExchangesState()) {
    _loadData();
  }

  ExchangeRepository get _exchangeRepo =>
      _ref.read(exchangeRepositoryProvider);

  HoldingRepository get _holdingRepo =>
      _ref.read(holdingRepositoryProvider);

  /// 加载交易所列表（硬编码）和已连接列表（本地 DB）
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. 支持的交易所列表：从 ExchangeInfo.supportedExchanges 硬编码
      final exchangesList = ExchangeInfo.supportedExchanges.map((info) {
        return Exchange(
          id: info.id,
          name: info.name,
          description: '',
          logoColor: _exchangeColorMap[info.id] ?? '#3B82F6',
          logoLetter: _computeLogoLetter(info.name),
          logoUrl: info.logoUrl,
          supportsSpot: info.supportsSource(BalanceSource.spot) ||
              info.supportsSource(BalanceSource.unified),
          supportsFutures: info.visibleAssetSupport.any(
            (s) => s.isAvailable && s.source.isFuturesLike,
          ),
          requiresPassphrase: info.requiresPassphrase,
          isFeatured: info.id == 'binance' || info.id == 'okx',
          status: 'available',
          category: 'exchange',
        );
      }).toList();

      // 2. 已连接交易所：从本地 DB 查询
      final connectedList = await _loadConnectedFromDB();

      state = state.copyWith(
        exchanges: exchangesList,
        connectedExchanges: connectedList,
        isLoading: false,
        hasLoadedOnce: true,
        error: null,
      );
    } catch (e) {
      debugPrint('Failed to load exchanges: $e');
      state = state.copyWith(
        isLoading: false,
        hasLoadedOnce: true,
        error: 'Unable to load exchanges. Please try again.',
      );
    }
  }

  /// 从 DB 读取已连接交易所
  Future<List<ConnectedExchange>> _loadConnectedFromDB() async {
    final accounts = await _exchangeRepo.getAllAccounts();
    return accounts.map((acct) {
      final info = ExchangeInfo.findById(acct.exchangeName);
      return ConnectedExchange(
        id: acct.id,
        exchangeName: acct.exchangeName,
        label: acct.label.isNotEmpty ? acct.label : acct.exchangeName,
        logoUrl: info?.logoUrl ?? '',
        isActive: acct.isActive,
        lastSyncAt: acct.lastSyncAt,
        syncStatus: acct.lastSyncAt != null ? 'success' : 'pending',
      );
    }).toList();
  }

  /// 公开重试方法
  Future<void> retry() => _loadData();

  /// 设置搜索查询
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 设置筛选条件
  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  /// 断开交易所连接（从本地 DB 删除 + 清理 Holdings）
  Future<void> disconnectExchange(String connectionId) async {
    state = state.copyWith(isLoading: true);
    try {
      // 先删除该交易所的所有持仓
      await _holdingRepo.deleteByExchangeId(connectionId);
      // 再删除交易所账户
      await _exchangeRepo.deleteById(connectionId);

      final updatedConnections = state.connectedExchanges
          .where((e) => e.id != connectionId)
          .toList();

      state = state.copyWith(
        connectedExchanges: updatedConnections,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Failed to disconnect exchange: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// 刷新已连接交易所列表
  Future<void> refreshConnectedExchanges() async {
    state = state.copyWith(isLoading: true);
    try {
      final connectedList = await _loadConnectedFromDB();
      state = state.copyWith(
        connectedExchanges: connectedList,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Failed to refresh connected exchanges: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

/// 交易所状态 Provider
final exchangesProvider =
    StateNotifierProvider<ExchangesNotifier, ExchangesState>((ref) {
  return ExchangesNotifier(ref);
});

/// 筛选后的交易所列表 Provider
final filteredExchangesProvider = Provider<List<Exchange>>((ref) {
  final state = ref.watch(exchangesProvider);
  return state.filteredExchanges;
});

/// 已连接的活跃交易所 ID 列表 Provider
final connectedExchangeIdsProvider = Provider<List<String>>((ref) {
  final state = ref.watch(exchangesProvider);
  return state.activeConnectedExchanges.map((e) => e.id).toList();
});
