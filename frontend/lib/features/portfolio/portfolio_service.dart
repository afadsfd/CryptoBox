import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

import '../../core/exchanges/adapters/base_adapter.dart';
import '../../core/exchanges/exchange_service.dart';
import '../../core/exchanges/models/balance.dart';
import '../../core/exchanges/models/exchange_info.dart';
import '../../core/local_storage/database.dart';
import '../../core/local_storage/repositories/exchange_repository.dart';
import '../../core/local_storage/repositories/holding_repository.dart';
import '../../core/local_storage/repositories/price_cache_repository.dart';
import '../../core/local_storage/repositories/snapshot_repository.dart';
import '../../core/market/coingecko_service.dart';
import '../../core/security/key_manager.dart';
import 'models/connected_source.dart';
import 'models/exchange_holdings_group.dart';
import 'models/history_data_point.dart';
import 'models/holding_item.dart';
import 'models/portfolio_summary.dart';

String _generateId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = Random.secure().nextInt(999999);
  return '${now}_$rand';
}

/// 快照冷却时间（1 小时内不重复保存）
const _snapshotCooldown = Duration(hours: 1);

/// 灰尘余额阈值（低于此美元价值的持仓被过滤）
const _dustThreshold = 1.0;

/// Portfolio 聚合服务
///
/// 组合 ExchangeRepository / HoldingRepository / SnapshotRepository /
/// PriceCacheRepository / ExchangeService / CoinGeckoService / KeyManager，
/// 实现资产聚合核心逻辑。
class PortfolioService {
  final ExchangeRepository exchangeRepository;
  final HoldingRepository holdingRepository;
  final SnapshotRepository snapshotRepository;
  final PriceCacheRepository priceCacheRepository;
  final ExchangeService exchangeService;
  final CoinGeckoService coingeckoService;
  final KeyManager keyManager;

  PortfolioService({
    required this.exchangeRepository,
    required this.holdingRepository,
    required this.snapshotRepository,
    required this.priceCacheRepository,
    required this.exchangeService,
    required this.coingeckoService,
    required this.keyManager,
  });

  // =========================================================================
  // getPortfolioSummary
  // =========================================================================

  /// 获取资产组合概览
  ///
  /// 1. 查询活跃账户 → 2. 解密凭证拉余额 → 3. 合并 symbol →
  /// 4. 定价（交易所 ticker 优先，CoinGecko fallback）→ 5. 过滤灰尘 →
  /// 6. 计算 24h 变化 → 7. 更新 Holdings 表 → 8. 保存快照
  Future<PortfolioSummary> getPortfolioSummary() async {
    // 1. 查询活跃账户
    final accounts = await exchangeRepository.getActiveAccounts();
    if (accounts.isEmpty) return PortfolioSummary.empty();

    // 2. 并发拉取每个交易所的余额（单个失败不阻塞）
    final accountBalances = await _fetchAllBalances(accounts);
    if (accountBalances.isEmpty) return PortfolioSummary.empty();

    // 3. 合并相同 symbol；同时记录每个账户的原始数据用于后续写入
    final merged = <String, _MergedBalance>{};
    final perAccountHoldings = <_AccountHolding>[];

    for (final ab in accountBalances) {
      for (final bal in ab.balances) {
        final sym = bal.symbol.toUpperCase();
        merged.putIfAbsent(sym, () => _MergedBalance());
        merged[sym]!.quantity += bal.total;
        merged[sym]!.free += bal.free;
        merged[sym]!.locked += bal.locked;

        perAccountHoldings.add(_AccountHolding(
          accountId: ab.account.id,
          symbol: sym,
          quantity: bal.total,
          free: bal.free,
          locked: bal.locked,
          source: bal.source,
        ));
      }
    }

    if (merged.isEmpty) return PortfolioSummary.empty();

    // 4. 获取价格和 24h 涨跌（合并为一次调用避免重复请求）
    final symbols = merged.keys.toList();
    final tickerResult = await _resolveTickerData(symbols, accountBalances);
    final prices = tickerResult.prices;
    final changes = tickerResult.changes;

    // 5. 计算每个币种 value 并过滤灰尘
    double totalValueUsd = 0;
    int holdingCount = 0;
    for (final entry in merged.entries) {
      final price = prices[entry.key] ?? 0;
      final value = entry.value.quantity * price;
      entry.value.priceUsd = price;
      entry.value.valueUsd = value;
      if (value >= _dustThreshold) {
        totalValueUsd += value;
        holdingCount++;
      }
    }

    // 6. 计算 24h 变化（加权）
    double change24hUsd = 0;
    for (final entry in merged.entries) {
      if (entry.value.valueUsd < _dustThreshold) continue;
      final chgPct = changes[entry.key] ?? 0;
      final val = entry.value.valueUsd;
      if (chgPct != 0 && (1 + chgPct / 100).abs() > 1e-9) {
        final valYesterday = val / (1 + chgPct / 100);
        change24hUsd += val - valYesterday;
      }
    }
    final yesterdayValue = totalValueUsd - change24hUsd;
    final change24hPercent =
        yesterdayValue.abs() > totalValueUsd * 0.001
            ? change24hUsd / yesterdayValue * 100
            : 0.0;

    // 7. 更新 Holdings 表
    await _upsertHoldings(perAccountHoldings, prices);

    // 8. 保存快照
    await _maybeSaveSnapshot(totalValueUsd);

    // 缓存价格到本地
    await _cachePrices(prices, changes);

    return PortfolioSummary(
      totalValueUsd: totalValueUsd,
      change24hUsd: change24hUsd,
      change24hPercent: change24hPercent,
      connectedExchanges: accounts.length,
      totalHoldings: holdingCount,
    );
  }

  // =========================================================================
  // getHoldings
  // =========================================================================

  /// 获取持仓列表（从 DB 读取，按 value_usd 降序，合并相同 symbol，过滤灰尘）
  Future<List<HoldingItem>> getHoldings() async {
    final holdings = await holdingRepository.getAll();
    if (holdings.isEmpty) return [];

    // 合并相同 symbol（跨交易所）
    final merged = <String, _MergedHolding>{};
    for (final h in holdings) {
      final sym = h.symbol.toUpperCase();
      merged.putIfAbsent(sym, () => _MergedHolding());
      merged[sym]!.quantity += h.quantity;
      merged[sym]!.priceUsd = h.priceUsd ?? merged[sym]!.priceUsd;
      merged[sym]!.valueUsd += h.valueUsd ?? 0;
    }

    // 获取 24h 涨跌
    final symbols = merged.keys.toList();
    final cachedPrices = await priceCacheRepository.getValidPrices(symbols);

    final items = <HoldingItem>[];
    for (final entry in merged.entries) {
      final val = entry.value.valueUsd;
      if (val < _dustThreshold) continue;
      items.add(HoldingItem(
        symbol: entry.key,
        quantity: entry.value.quantity,
        priceUsd: entry.value.priceUsd,
        valueUsd: val,
        change24h: cachedPrices[entry.key]?.change24h,
      ));
    }

    // 按 value_usd 降序
    items.sort((a, b) => b.valueUsd.compareTo(a.valueUsd));
    return items;
  }

  /// 按交易所账户分组的持仓（不合并跨所同 symbol）
  Future<List<ExchangeHoldingsGroup>> getHoldingsGroupedByExchange() async {
    final accounts = await exchangeRepository.getAllAccounts();
    if (accounts.isEmpty) return [];

    final groups = <ExchangeHoldingsGroup>[];

    for (final acct in accounts) {
      final rows = await holdingRepository.getByExchangeId(acct.id);
      final rawLines = <AccountHoldingLine>[];
      var total = 0.0;

      for (final h in rows) {
        final v = h.valueUsd ?? 0;
        if (v < _dustThreshold) continue;
        total += v;
        rawLines.add(AccountHoldingLine(
          symbol: h.symbol.toUpperCase(),
          quantity: h.quantity,
          priceUsd: h.priceUsd ?? 0,
          valueUsd: v,
          change24h: null,
          source: _parseSource(h.source),
        ));
      }

      if (rawLines.isEmpty) continue;

      final symbols = rawLines.map((a) => a.symbol).toList();
      final cached = await priceCacheRepository.getValidPrices(symbols);
      final withChg = rawLines
          .map(
            (a) => AccountHoldingLine(
              symbol: a.symbol,
              quantity: a.quantity,
              priceUsd: a.priceUsd,
              valueUsd: a.valueUsd,
              change24h: cached[a.symbol]?.change24h,
              source: a.source,
            ),
          )
          .toList()
        ..sort((a, b) => b.valueUsd.compareTo(a.valueUsd));

      // 按 source 拆分子组
      final bySource = <BalanceSource, List<AccountHoldingLine>>{};
      for (final line in withChg) {
        bySource.putIfAbsent(line.source, () => []).add(line);
      }
      final subGroups = <SourceHoldingsSubGroup>[];
      for (final src in const [
        BalanceSource.spot,
        BalanceSource.earn,
        BalanceSource.futures,
      ]) {
        final lines = bySource[src];
        if (lines == null || lines.isEmpty) continue;
        final sub = lines.fold<double>(0, (s, l) => s + l.valueUsd);
        subGroups.add(SourceHoldingsSubGroup(
          source: src,
          totalValueUsd: sub,
          holdings: lines,
        ));
      }

      final info = ExchangeInfo.findById(acct.exchangeName);
      groups.add(ExchangeHoldingsGroup(
        accountId: acct.id,
        label: acct.label.isNotEmpty
            ? acct.label
            : (info?.name ?? acct.exchangeName),
        exchangeId: acct.exchangeName,
        displayName: info?.name ?? acct.exchangeName,
        logoUrl: info?.logoUrl ?? '',
        totalValueUsd: total,
        holdings: withChg,
        sourceGroups: subGroups,
      ));
    }

    groups.sort((a, b) => b.totalValueUsd.compareTo(a.totalValueUsd));
    return groups;
  }

  // =========================================================================
  // getPortfolioHistory
  // =========================================================================

  /// 获取资产趋势历史
  ///
  /// [period] 支持: "7d", "30d", "90d"
  Future<List<HistoryDataPoint>> getPortfolioHistory(String period) async {
    final days = _periodToDays(period);
    final snapshots = await snapshotRepository.getRecent(days);
    return snapshots
        .map((s) => HistoryDataPoint(
              timestamp: s.snapshotAt,
              totalValue: s.totalValueUsd,
            ))
        .toList();
  }

  // =========================================================================
  // getConnectedSources
  // =========================================================================

  /// 获取已连接的数据源列表（含资产占比）
  Future<List<ConnectedSource>> getConnectedSources() async {
    final accounts = await exchangeRepository.getAllAccounts();
    if (accounts.isEmpty) return [];

    // 计算每个交易所的总资产
    double grandTotal = 0;
    final sourceValues = <String, double>{};

    for (final acct in accounts) {
      final holdings = await holdingRepository.getByExchangeId(acct.id);
      double acctValue = 0;
      for (final h in holdings) {
        acctValue += h.valueUsd ?? 0;
      }
      sourceValues[acct.id] = acctValue;
      grandTotal += acctValue;
    }

    return accounts.map((acct) {
      final val = sourceValues[acct.id] ?? 0;
      final pct = grandTotal > 0 ? val / grandTotal * 100 : 0.0;
      final info = ExchangeInfo.findById(acct.exchangeName);
      return ConnectedSource(
        id: acct.id,
        exchangeName: acct.exchangeName,
        label: acct.label.isNotEmpty ? acct.label : acct.exchangeName,
        totalValueUsd: val,
        percentage: pct,
        lastSyncAt: acct.lastSyncAt,
        isActive: acct.isActive,
        logoUrl: info?.logoUrl ?? '',
      );
    }).toList();
  }

  // =========================================================================
  // syncAllExchanges
  // =========================================================================

  /// 同步所有活跃交易所
  Future<void> syncAllExchanges() async {
    final accounts = await exchangeRepository.getActiveAccounts();
    if (accounts.isEmpty) return;

    // 并发同步，单个失败不阻塞
    await Future.wait(
      accounts.map((acct) => syncSingleExchange(acct.id)),
      eagerError: false,
    );

    // 保存快照
    await saveSnapshot();
  }

  // =========================================================================
  // syncSingleExchange
  // =========================================================================

  /// 同步单个交易所账户
  Future<void> syncSingleExchange(String accountId) async {
    final account = await exchangeRepository.getById(accountId);
    if (account == null) {
      debugPrint('[PortfolioService] Account not found: $accountId');
      return;
    }

    try {
      // 解密凭证
      final creds = keyManager.decryptCredentials(
        encryptedApiKey: account.encryptedApiKey,
        encryptedSecret: account.encryptedSecret,
        encryptedPassphrase: account.encryptedPassphrase,
      );

      // 获取适配器
      final adapter = exchangeService.getAdapter(account.exchangeName);
      if (adapter == null) {
        debugPrint('[PortfolioService] No adapter for ${account.exchangeName}');
        return;
      }

      // 拉取余额（现货 + 理财 + 合约）
      final balances = await adapter.getAllBalances(
        apiKey: creds['apiKey']!,
        apiSecret: creds['apiSecret']!,
        passphrase: creds['passphrase'],
      );

      // 获取价格
      final symbols = balances.map((b) => b.symbol.toUpperCase()).toList();
      final prices = await _resolvePricesForSingleExchange(
        adapter: adapter,
        symbols: symbols,
      );

      // 构造 holdings 数据并写入（带 source 区分）
      final entries = balances.map((b) {
        final sym = b.symbol.toUpperCase();
        final price = prices[sym] ?? 0;
        return HoldingsCompanion.insert(
          id: '${account.id}_${sym}_${b.source.name}',
          exchangeAccountId: account.id,
          symbol: sym,
          quantity: Value(b.total),
          free: Value(b.free),
          locked: Value(b.locked),
          priceUsd: Value(price),
          valueUsd: Value(b.total * price),
          source: Value(b.source.name),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();

      await holdingRepository.replaceForExchange(account.id, entries);
      await exchangeRepository.updateSyncTime(account.id);

      // 缓存价格
      await _cachePrices(prices, {});
    } catch (e, st) {
      debugPrint('[PortfolioService] Sync failed for $accountId: $e\n$st');
    }
  }

  // =========================================================================
  // saveSnapshot
  // =========================================================================

  /// 计算当前总资产并保存快照
  Future<void> saveSnapshot() async {
    final holdings = await holdingRepository.getAll();
    double total = 0;
    for (final h in holdings) {
      total += h.valueUsd ?? 0;
    }
    if (total <= 0) return;
    await _maybeSaveSnapshot(total);
  }

  // =========================================================================
  // Private: 拉取余额
  // =========================================================================

  /// 并发拉取所有账户余额（单个失败返回空列表）
  Future<List<_AccountBalanceResult>> _fetchAllBalances(
    List<ExchangeAccount> accounts,
  ) async {
    final futures = accounts.map((acct) async {
      try {
        return await _fetchAccountBalance(acct);
      } catch (e) {
        debugPrint(
          '[PortfolioService] Failed to fetch balance for '
          '${acct.exchangeName}(${acct.id}): $e',
        );
        // 回退到 DB 缓存
        return await _getCachedBalance(acct);
      }
    });

    final results = await Future.wait(futures);
    return results.where((r) => r.balances.isNotEmpty).toList();
  }

  Future<_AccountBalanceResult> _fetchAccountBalance(
    ExchangeAccount account,
  ) async {
    final creds = keyManager.decryptCredentials(
      encryptedApiKey: account.encryptedApiKey,
      encryptedSecret: account.encryptedSecret,
      encryptedPassphrase: account.encryptedPassphrase,
    );

    final adapter = exchangeService.getAdapter(account.exchangeName);
    if (adapter == null) {
      throw Exception('No adapter for ${account.exchangeName}');
    }

    final balances = await adapter.getAllBalances(
      apiKey: creds['apiKey']!,
      apiSecret: creds['apiSecret']!,
      passphrase: creds['passphrase'],
    );

    return _AccountBalanceResult(account: account, balances: balances);
  }

  /// 从 Holdings 表回退读取缓存余额
  Future<_AccountBalanceResult> _getCachedBalance(
    ExchangeAccount account,
  ) async {
    final holdings = await holdingRepository.getByExchangeId(account.id);
    final balances = holdings
        .map((h) => _CachedBalance(
              symbol: h.symbol,
              total: h.quantity,
              free: h.free,
              locked: h.locked,
              source: _parseSource(h.source),
            ))
        .toList();
    return _AccountBalanceResult(account: account, balances: balances);
  }

  // =========================================================================
  // Private: 价格解析
  // =========================================================================

  /// 一次性解析价格和 24h 涨跌：交易所 ticker 优先，CoinGecko fallback
  Future<_TickerResult> _resolveTickerData(
    List<String> symbols,
    List<_AccountBalanceResult> accountBalances,
  ) async {
    final prices = <String, double>{};
    final changes = <String, double>{};

    // 每个交易所只请求一次 ticker
    final seenExchanges = <String>{};
    for (final ab in accountBalances) {
      final exchName = ab.account.exchangeName;
      if (seenExchanges.contains(exchName)) continue;
      seenExchanges.add(exchName);

      try {
        final adapter = exchangeService.getAdapter(exchName);
        if (adapter == null) continue;

        final tickerSymbols = symbols.map((s) => '$s/USDT').toList();
        final tickers = await adapter.getTickers(tickerSymbols);

        for (final t in tickers.values) {
          final baseSym = t.symbol.split('/').first.toUpperCase();
          if (!prices.containsKey(baseSym)) {
            prices[baseSym] = t.lastPrice;
          }
          if (!changes.containsKey(baseSym) && t.change24h != null) {
            changes[baseSym] = t.change24h!;
          }
        }
      } catch (e) {
        debugPrint(
          '[PortfolioService] Failed to get tickers from $exchName: $e',
        );
      }
    }

    // CoinGecko fallback for prices
    final missingPrices =
        symbols.where((s) => !prices.containsKey(s)).toList();
    if (missingPrices.isNotEmpty) {
      try {
        final cgPrices = await coingeckoService.getPrices(missingPrices);
        prices.addAll(cgPrices);
      } catch (e) {
        debugPrint('[PortfolioService] CoinGecko price fallback failed: $e');
      }
    }

    // CoinGecko fallback for 24h changes
    final missingChanges =
        symbols.where((s) => !changes.containsKey(s)).toList();
    if (missingChanges.isNotEmpty) {
      try {
        final cgChanges = await coingeckoService.get24hChange(missingChanges);
        changes.addAll(cgChanges);
      } catch (_) {}
    }

    // 稳定币兜底
    for (final s in symbols) {
      if (_isStablecoin(s) && !prices.containsKey(s)) {
        prices[s] = 1.0;
      }
    }

    return _TickerResult(prices: prices, changes: changes);
  }

  /// 单交易所同步时获取价格
  Future<Map<String, double>> _resolvePricesForSingleExchange({
    required BaseExchangeAdapter adapter,
    required List<String> symbols,
  }) async {
    final prices = <String, double>{};

    try {
      final tickerSymbols = symbols.map((s) => '$s/USDT').toList();
      final tickers = await adapter.getTickers(tickerSymbols);
      for (final t in tickers.values) {
        final baseSym = t.symbol.split('/').first.toUpperCase();
        prices[baseSym] = t.lastPrice;
      }
    } catch (_) {}

    // CoinGecko fallback
    final missing = symbols.where((s) => !prices.containsKey(s)).toList();
    if (missing.isNotEmpty) {
      try {
        final cgPrices = await coingeckoService.getPrices(missing);
        prices.addAll(cgPrices);
      } catch (_) {}
    }

    for (final s in symbols) {
      if (_isStablecoin(s) && !prices.containsKey(s)) {
        prices[s] = 1.0;
      }
    }

    return prices;
  }

  // =========================================================================
  // Private: 数据写入
  // =========================================================================

  /// 批量更新 Holdings 表
  Future<void> _upsertHoldings(
    List<_AccountHolding> holdings,
    Map<String, double> prices,
  ) async {
    // 按 accountId 分组
    final grouped = <String, List<_AccountHolding>>{};
    for (final h in holdings) {
      grouped.putIfAbsent(h.accountId, () => []).add(h);
    }

    for (final entry in grouped.entries) {
      final accountId = entry.key;
      final entries = entry.value.map((h) {
        final price = prices[h.symbol] ?? 0;
        return HoldingsCompanion.insert(
          id: '${accountId}_${h.symbol}_${h.source.name}',
          exchangeAccountId: accountId,
          symbol: h.symbol,
          quantity: Value(h.quantity),
          free: Value(h.free),
          locked: Value(h.locked),
          priceUsd: Value(price),
          valueUsd: Value(h.quantity * price),
          source: Value(h.source.name),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();

      await holdingRepository.replaceForExchange(accountId, entries);
    }
  }

  /// 保存快照（冷却 1h）
  Future<void> _maybeSaveSnapshot(double totalValueUsd) async {
    // 检查冷却
    final recent = await snapshotRepository.getRecent(1);
    if (recent.isNotEmpty) {
      final last = recent.last;
      if (DateTime.now().difference(last.snapshotAt) < _snapshotCooldown) {
        return;
      }
    }

    await snapshotRepository.insert(PortfolioSnapshotsCompanion.insert(
      id: _generateId(),
      totalValueUsd: totalValueUsd,
      snapshotAt: DateTime.now(),
    ));
  }

  /// 缓存价格到本地 PriceCache 表
  Future<void> _cachePrices(
    Map<String, double> prices,
    Map<String, double> changes,
  ) async {
    if (prices.isEmpty) return;
    await priceCacheRepository.upsertPrices(prices, changes: changes);
  }

  // =========================================================================
  // Helpers
  // =========================================================================

  int _periodToDays(String period) {
    switch (period) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      default:
        return 30;
    }
  }

  static BalanceSource _parseSource(String? s) {
    switch (s) {
      case 'earn':
        return BalanceSource.earn;
      case 'futures':
        return BalanceSource.futures;
      case 'spot':
      default:
        return BalanceSource.spot;
    }
  }

  static bool _isStablecoin(String symbol) {
    const stables = {'USDT', 'USDC', 'DAI', 'BUSD', 'TUSD', 'USDP', 'FRAX', 'LUSD'};
    return stables.contains(symbol.toUpperCase());
  }
}

// =========================================================================
// Internal data classes
// =========================================================================

class _AccountBalanceResult {
  final ExchangeAccount account;
  final List<Balance> balances;

  _AccountBalanceResult({required this.account, required this.balances});
}

class _MergedBalance {
  double quantity = 0;
  double free = 0;
  double locked = 0;
  double priceUsd = 0;
  double valueUsd = 0;
}

class _MergedHolding {
  double quantity = 0;
  double priceUsd = 0;
  double valueUsd = 0;
}

class _AccountHolding {
  final String accountId;
  final String symbol;
  final double quantity;
  final double free;
  final double locked;
  final BalanceSource source;

  _AccountHolding({
    required this.accountId,
    required this.symbol,
    required this.quantity,
    required this.free,
    required this.locked,
    this.source = BalanceSource.spot,
  });
}

/// 缓存回退时的伪 Balance（携带 source 信息）
class _CachedBalance implements Balance {
  @override
  final String symbol;
  @override
  final double total;
  @override
  final double free;
  @override
  final double locked;
  @override
  final BalanceSource source;

  _CachedBalance({
    required this.symbol,
    required this.total,
    required this.free,
    required this.locked,
    this.source = BalanceSource.spot,
  });

  @override
  Balance copyWith({
    String? symbol,
    double? total,
    double? free,
    double? locked,
    BalanceSource? source,
  }) =>
      Balance(
        symbol: symbol ?? this.symbol,
        total: total ?? this.total,
        free: free ?? this.free,
        locked: locked ?? this.locked,
        source: source ?? this.source,
      );
}

/// 合并的 ticker 结果（价格 + 24h 涨跌）
class _TickerResult {
  final Map<String, double> prices;
  final Map<String, double> changes;

  _TickerResult({required this.prices, required this.changes});
}
