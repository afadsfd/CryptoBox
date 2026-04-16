import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/raster_image_url.dart';
import 'models/price_point.dart';

/// 缓存的价格数据
class CachedPrice {
  final double price;
  final double? change24h;
  final DateTime timestamp;

  CachedPrice({
    required this.price,
    this.change24h,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp).inSeconds > CoinGeckoService.cacheTtlSeconds;
}

/// CoinGecko 价格服务
///
/// 提供实时价格、24h 涨跌幅、历史价格查询，
/// 内置内存缓存（60 秒过期）和 429 限流重试。
class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const int cacheTtlSeconds = 60;
  static const int _historyCacheTtlSeconds = 300;
  static const Duration _httpTimeout = Duration(seconds: 15);

  /// 稳定币列表，直接返回 1.0
  static const Set<String> _stablecoins = {
    'USDT', 'USDC', 'DAI', 'BUSD', 'TUSD', 'USDP', 'FRAX', 'LUSD',
  };

  /// Symbol -> CoinGecko ID 映射（TOP 50+ 主流币种）
  static const Map<String, String> symbolMap = {
    // --- 市值 TOP 10 ---
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'USDT': 'tether',
    'BNB': 'binancecoin',
    'SOL': 'solana',
    'XRP': 'ripple',
    'USDC': 'usd-coin',
    'ADA': 'cardano',
    'DOGE': 'dogecoin',
    'AVAX': 'avalanche-2',
    // --- 11-20 ---
    'TRX': 'tron',
    'DOT': 'polkadot',
    'LINK': 'chainlink',
    'TON': 'the-open-network',
    'MATIC': 'matic-network',
    'SHIB': 'shiba-inu',
    'ICP': 'internet-computer',
    'DAI': 'dai',
    'LTC': 'litecoin',
    'BCH': 'bitcoin-cash',
    // --- 21-30 ---
    'UNI': 'uniswap',
    'ATOM': 'cosmos',
    'XLM': 'stellar',
    'NEAR': 'near',
    'OKB': 'okb',
    'APT': 'aptos',
    'FIL': 'filecoin',
    'ARB': 'arbitrum',
    'OP': 'optimism',
    'SUI': 'sui',
    // --- 31-40 ---
    'HBAR': 'hedera-hashgraph',
    'VET': 'vechain',
    'MKR': 'maker',
    'GRT': 'the-graph',
    'INJ': 'injective-protocol',
    'THETA': 'theta-token',
    'RUNE': 'thorchain',
    'FTM': 'fantom',
    'AAVE': 'aave',
    'ALGO': 'algorand',
    // --- 41-50 ---
    'FLOW': 'flow',
    'XTZ': 'tezos',
    'AXS': 'axie-infinity',
    'SAND': 'the-sandbox',
    'MANA': 'decentraland',
    'EOS': 'eos',
    'EGLD': 'elrond-erd-2',
    'SNX': 'havven',
    'CRV': 'curve-dao-token',
    'LDO': 'lido-dao',
    // --- 51-60+ 补充 ---
    'PEPE': 'pepe',
    'WIF': 'dogwifcoin',
    'BUSD': 'binance-usd',
    'GT': 'gatechain-token',
    'BGB': 'bitget-token',
    'IMX': 'immutable-x',
    'RNDR': 'render-token',
    'QNT': 'quant-network',
    'COMP': 'compound-governance-token',
    'RPL': 'rocket-pool',
    'ENS': 'ethereum-name-service',
    'DYDX': 'dydx',
    'GMX': 'gmx',
    'WLD': 'worldcoin-wld',
    'SEI': 'sei-network',
    'TIA': 'celestia',
    'BONK': 'bonk',
    'FET': 'fetch-ai',
    'AGIX': 'singularitynet',
    'OCEAN': 'ocean-protocol',
    'CRO': 'crypto-com-chain',
    'TUSD': 'true-usd',
    'USDP': 'paxos-standard',
    'FRAX': 'frax',
    'LUSD': 'liquity-usd',
    '1INCH': '1inch',
    'SUSHI': 'sushi',
    'BAL': 'balancer',
    'YFI': 'yearn-finance',
    'ZRX': '0x',
    'BAT': 'basic-attention-token',
    'CELO': 'celo',
    'KAVA': 'kava',
    'ZEC': 'zcash',
    'DASH': 'dash',
    'NEO': 'neo',
    'WAVES': 'waves',
    'KSM': 'kusama',
    'IOTA': 'iota',
    'ONE': 'harmony',
    'ZIL': 'zilliqa',
    'ENJ': 'enjincoin',
    'CHZ': 'chiliz',
    'GALA': 'gala',
    'APE': 'apecoin',
    'CKB': 'nervos-network',
    'ROSE': 'oasis-network',
    'MINA': 'mina-protocol',
    'STX': 'blockstack',
    'KCS': 'kucoin-shares',
  };

  // --- 内存缓存 ---
  final Map<String, CachedPrice> _priceCache = {};
  final Map<String, _CachedHistory> _historyCache = {};
  final Map<String, String> _coinImageUrlCache = {};

  final http.Client _client;

  /// 图标 URL 持久化回调（由上层注入，写入 DB）
  void Function(Map<String, String> urls)? onImageUrlsFetched;

  CoinGeckoService({http.Client? client}) : _client = client ?? http.Client();

  /// 从 DB 恢复已缓存的图标 URL（App 启动时调用一次）
  void restoreImageUrlCache(Map<String, String> urls) {
    _coinImageUrlCache.addAll(urls);
  }

  /// 释放 HTTP 客户端
  void dispose() {
    _client.close();
  }

  // ────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────

  /// 批量获取实时 USD 价格
  ///
  /// 返回 `{symbol: price}` 映射，找不到的币种不会出现在结果中。
  Future<Map<String, double>> getPrices(List<String> symbols) async {
    final result = <String, double>{};
    final toFetch = <String>[];

    for (final sym in symbols) {
      final upper = sym.toUpperCase();

      // 稳定币直接返回 1.0
      if (_stablecoins.contains(upper)) {
        result[upper] = 1.0;
        continue;
      }

      // 检查缓存
      final cached = _priceCache[upper];
      if (cached != null && !cached.isExpired) {
        result[upper] = cached.price;
        continue;
      }

      toFetch.add(upper);
    }

    if (toFetch.isEmpty) return result;

    // 解析 symbol -> coingecko id
    final idMap = <String, String>{};
    for (final sym in toFetch) {
      idMap[sym] = _resolveId(sym);
    }

    final ids = idMap.values.join(',');
    final data = await _request(
      '$_baseUrl/simple/price',
      queryParameters: {
        'ids': ids,
        'vs_currencies': 'usd',
        'include_24hr_change': 'true',
      },
    );

    if (data != null && data is Map<String, dynamic>) {
      for (final sym in toFetch) {
        final cgId = idMap[sym]!;
        final coinData = data[cgId];
        if (coinData is Map<String, dynamic>) {
          final price = _toDouble(coinData['usd']);
          final change = _toDouble(coinData['usd_24h_change']);
          if (price != null) {
            result[sym] = price;
            _priceCache[sym] = CachedPrice(
              price: price,
              change24h: change,
              timestamp: DateTime.now(),
            );
          }
        }
      }
    }

    return result;
  }

  /// 批量获取 24h 涨跌百分比
  ///
  /// 返回 `{symbol: changePercent}`，如 `{"BTC": -2.34, "ETH": 1.56}`
  Future<Map<String, double>> get24hChange(List<String> symbols) async {
    final result = <String, double>{};
    final toFetch = <String>[];

    for (final sym in symbols) {
      final upper = sym.toUpperCase();
      if (_stablecoins.contains(upper)) {
        result[upper] = 0.0;
        continue;
      }
      // 使用缓存中的 change24h
      final cached = _priceCache[upper];
      if (cached != null && !cached.isExpired && cached.change24h != null) {
        result[upper] = cached.change24h!;
        continue;
      }
      toFetch.add(upper);
    }

    if (toFetch.isEmpty) return result;

    // 复用 getPrices（已包含 include_24hr_change=true）
    await getPrices(toFetch);

    // 从更新后的缓存读取
    for (final sym in toFetch) {
      final cached = _priceCache[sym];
      if (cached != null && cached.change24h != null) {
        result[sym] = cached.change24h!;
      }
    }

    return result;
  }

  /// 获取历史价格
  ///
  /// [symbol] 币种符号（如 BTC）
  /// [days] 天数（1, 7, 30, 90, 365 等）
  Future<List<PricePoint>> getPriceHistory(String symbol, {int days = 30}) async {
    final upper = symbol.toUpperCase();

    // 检查缓存
    final cacheKey = '${upper}_$days';
    final cached = _historyCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final cgId = _resolveId(upper);
    final data = await _request(
      '$_baseUrl/coins/$cgId/market_chart',
      queryParameters: {
        'vs_currency': 'usd',
        'days': days.toString(),
      },
    );

    if (data == null || data is! Map<String, dynamic>) return [];

    final prices = data['prices'];
    if (prices == null || prices is! List) return [];

    final points = <PricePoint>[];
    for (final item in prices) {
      if (item is List && item.length >= 2) {
        final tsMs = _toDouble(item[0]);
        final price = _toDouble(item[1]);
        if (tsMs != null && price != null) {
          points.add(PricePoint(
            timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs.toInt(), isUtc: true),
            price: price,
          ));
        }
      }
    }

    _historyCache[cacheKey] = _CachedHistory(
      data: points,
      timestamp: DateTime.now(),
    );

    return points;
  }

  /// 获取单个币种的当前价格，找不到返回 null
  Future<double?> getPrice(String symbol) async {
    final prices = await getPrices([symbol]);
    return prices[symbol.toUpperCase()];
  }

  /// 按持仓 symbol 批量拉取 CoinGecko 小图标 URL（无映射或 API 失败则不在 map 中）。
  Future<Map<String, String>> getCoinSmallImageUrls(List<String> symbols) async {
    final result = <String, String>{};
    final upperUnique = symbols.map((s) => s.toUpperCase()).toSet().toList();
    final toFetch = <String>[];

    const stableSmall =
        'https://assets.coingecko.com/coins/images/6319/small/USD_Coin_icon.png';
    final stableIcon = upgradeRasterImageUrl(stableSmall);

    for (final sym in upperUnique) {
      if (_stablecoins.contains(sym)) {
        result[sym] = stableIcon;
        continue;
      }
      final cached = _coinImageUrlCache[sym];
      if (cached != null) {
        final hi = upgradeRasterImageUrl(cached);
        if (hi != cached) {
          _coinImageUrlCache[sym] = hi;
        }
        result[sym] = hi;
        continue;
      }
      toFetch.add(sym);
    }

    const chunk = 40;
    for (var i = 0; i < toFetch.length; i += chunk) {
      final part = toFetch.sublist(i, min(i + chunk, toFetch.length));
      final symParam = part.map((s) => s.toLowerCase()).join(',');
      final data = await _request(
        '$_baseUrl/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'symbols': symParam,
          'per_page': '250',
          'page': '1',
          'sparkline': 'false',
        },
      );

      if (data is List) {
        for (final raw in data) {
          if (raw is! Map<String, dynamic>) continue;
          final sym = (raw['symbol'] as String?)?.toUpperCase();
          final img = raw['image'] as String?;
          if (sym != null && img != null) {
            final hi = upgradeRasterImageUrl(img);
            _coinImageUrlCache[sym] = hi;
            result[sym] = hi;
          }
        }
      }
    }

    // 持久化新拉取的 URL 到 DB
    if (toFetch.isNotEmpty && result.isNotEmpty) {
      onImageUrlsFetched?.call(Map<String, String>.from(result));
    }

    return result;
  }

  /// 仅从内存缓存中读取已有的图片 URL（不发网络请求）
  Map<String, String> getCachedImageUrls(List<String> symbols) {
    final result = <String, String>{};
    const stableSmall =
        'https://assets.coingecko.com/coins/images/6319/small/USD_Coin_icon.png';
    final stableIcon = upgradeRasterImageUrl(stableSmall);

    for (final sym in symbols.map((s) => s.toUpperCase()).toSet()) {
      if (_stablecoins.contains(sym)) {
        result[sym] = stableIcon;
        continue;
      }
      final cached = _coinImageUrlCache[sym];
      if (cached != null) {
        result[sym] = cached;
      }
    }
    return result;
  }

  /// 清除所有缓存
  void clearCache() {
    _priceCache.clear();
    _historyCache.clear();
    _coinImageUrlCache.clear();
  }

  // ────────────────────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────────────────────

  /// 将 symbol 解析为 CoinGecko ID
  String _resolveId(String upperSymbol) {
    return symbolMap[upperSymbol] ?? upperSymbol.toLowerCase();
  }

  /// 带 429 重试的 HTTP GET
  Future<dynamic> _request(
    String url, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParameters);

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_httpTimeout);

        if (response.statusCode == 429) {
          if (attempt == 0) {
            final retryAfter = int.tryParse(
                  response.headers['retry-after'] ?? '',
                ) ??
                5;
            debugPrint(
              '[CoinGecko] Rate limit hit, retrying after ${retryAfter}s',
            );
            await Future<void>.delayed(Duration(seconds: retryAfter));
            continue;
          }
          debugPrint('[CoinGecko] Rate limit hit twice, giving up');
          return null;
        }

        if (response.statusCode == 404) {
          debugPrint('[CoinGecko] 404 for $url');
          return null;
        }

        if (response.statusCode != 200) {
          debugPrint(
            '[CoinGecko] HTTP ${response.statusCode} for $url',
          );
          return null;
        }

        return json.decode(response.body);
      } on TimeoutException {
        debugPrint('[CoinGecko] Timeout for $url');
        return null;
      } catch (e) {
        debugPrint('[CoinGecko] Request error: $e');
        return null;
      }
    }
    return null;
  }

  /// 安全地将动态值转为 double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// 历史价格缓存项
class _CachedHistory {
  final List<PricePoint> data;
  final DateTime timestamp;

  _CachedHistory({required this.data, required this.timestamp});

  bool get isExpired =>
      DateTime.now().difference(timestamp).inSeconds >
      CoinGeckoService._historyCacheTtlSeconds;
}
