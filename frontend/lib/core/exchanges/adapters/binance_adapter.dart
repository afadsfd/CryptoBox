import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/balance.dart';
import '../models/ticker.dart';
import 'base_adapter.dart';

/// Binance 交易所适配器
class BinanceAdapter extends BaseExchangeAdapter {
  static const _timeout = Duration(seconds: 15);
  static const _fapiBase = 'https://fapi.binance.com'; // U 本位合约
  static const _dapiBase = 'https://dapi.binance.com'; // 币本位合约

  @override
  String get exchangeId => 'binance';

  @override
  String get baseUrl => 'https://api.binance.com';

  /// HMAC-SHA256 签名
  String _sign(String queryString, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(queryString));
    return digest.toString();
  }

  @override
  Future<bool> verifyConnection({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    try {
      await getSpotBalance(apiKey: apiKey, apiSecret: apiSecret);
      return true;
    } on ExchangeAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Balance>> getSpotBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    final data = await _signedGet(
      host: baseUrl,
      path: '/api/v3/account',
      apiKey: apiKey,
      apiSecret: apiSecret,
    ) as Map<String, dynamic>;

    final balances = data['balances'] as List<dynamic>? ?? [];

    return balances
        .map((b) {
          final free = double.tryParse(b['free']?.toString() ?? '0') ?? 0;
          final locked =
              double.tryParse(b['locked']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: b['asset'] as String? ?? '',
            total: free + locked,
            free: free,
            locked: locked,
            source: BalanceSource.spot,
          );
        })
        .where((b) => b.total > 0)
        .toList();
  }

  /// 理财账户（活期 Simple Earn Flexible + 定期 Locked）
  @override
  Future<List<Balance>> getEarnBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    // 1) 活期 2) 定期 3) 资金账户 —— 并发拉取
    final results = await Future.wait([
      _fetchEarnFlexible(apiKey, apiSecret).catchError((e) {
        debugPrint('[Binance] earn flexible failed: $e');
        return <Balance>[];
      }),
      _fetchEarnLocked(apiKey, apiSecret).catchError((e) {
        debugPrint('[Binance] earn locked failed: $e');
        return <Balance>[];
      }),
      _fetchFundingWallet(apiKey, apiSecret).catchError((e) {
        debugPrint('[Binance] funding wallet failed: $e');
        return <Balance>[];
      }),
    ]);

    return mergeBalances(results.expand((b) => b).toList());
  }

  /// 合约账户（U 本位 + 币本位）
  @override
  Future<List<Balance>> getFuturesBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    // U 本位合约  &  币本位合约 —— 并发
    final results = await Future.wait([
      _fetchUsdtMFutures(apiKey, apiSecret).catchError((e) {
        debugPrint('[Binance] USDT-M futures failed: $e');
        return <Balance>[];
      }),
      _fetchCoinMFutures(apiKey, apiSecret).catchError((e) {
        debugPrint('[Binance] COIN-M futures failed: $e');
        return <Balance>[];
      }),
    ]);

    return mergeBalances(results.expand((b) => b).toList());
  }

  // ============ Earn 细分 ============

  Future<List<Balance>> _fetchEarnFlexible(
      String apiKey, String apiSecret) async {
    final list = <Balance>[];
    int current = 1;
    const size = 100;
    while (true) {
      final data = await _signedGet(
        host: baseUrl,
        path: '/sapi/v1/simple-earn/flexible/position',
        apiKey: apiKey,
        apiSecret: apiSecret,
        params: {'current': '$current', 'size': '$size'},
      ) as Map<String, dynamic>;
      final rows = data['rows'] as List<dynamic>? ?? [];
      for (final r in rows) {
        final asset = r['asset']?.toString() ?? '';
        final amount =
            double.tryParse(r['totalAmount']?.toString() ?? '0') ?? 0;
        if (asset.isEmpty || amount <= 0) continue;
        list.add(Balance(
          symbol: asset,
          total: amount,
          free: amount,
          locked: 0,
          source: BalanceSource.earn,
        ));
      }
      final total = (data['total'] as num?)?.toInt() ?? 0;
      if (current * size >= total || rows.isEmpty) break;
      current++;
      if (current > 20) break; // 安全阀
    }
    return list;
  }

  Future<List<Balance>> _fetchEarnLocked(
      String apiKey, String apiSecret) async {
    final list = <Balance>[];
    int current = 1;
    const size = 100;
    while (true) {
      final data = await _signedGet(
        host: baseUrl,
        path: '/sapi/v1/simple-earn/locked/position',
        apiKey: apiKey,
        apiSecret: apiSecret,
        params: {'current': '$current', 'size': '$size'},
      ) as Map<String, dynamic>;
      final rows = data['rows'] as List<dynamic>? ?? [];
      for (final r in rows) {
        final asset = r['asset']?.toString() ?? '';
        final amount = double.tryParse(r['amount']?.toString() ?? '0') ?? 0;
        if (asset.isEmpty || amount <= 0) continue;
        list.add(Balance(
          symbol: asset,
          total: amount,
          free: 0,
          locked: amount,
          source: BalanceSource.earn,
        ));
      }
      final total = (data['total'] as num?)?.toInt() ?? 0;
      if (current * size >= total || rows.isEmpty) break;
      current++;
      if (current > 20) break;
    }
    return list;
  }

  Future<List<Balance>> _fetchFundingWallet(
      String apiKey, String apiSecret) async {
    // POST /sapi/v1/asset/get-funding-asset
    final data = await _signedRequest(
      host: baseUrl,
      path: '/sapi/v1/asset/get-funding-asset',
      method: 'POST',
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
    if (data is! List) return <Balance>[];
    return data
        .map((item) {
          final asset = item['asset']?.toString() ?? '';
          final free = double.tryParse(item['free']?.toString() ?? '0') ?? 0;
          final locked =
              double.tryParse(item['locked']?.toString() ?? '0') ?? 0;
          final freeze =
              double.tryParse(item['freeze']?.toString() ?? '0') ?? 0;
          final total = free + locked + freeze;
          return Balance(
            symbol: asset,
            total: total,
            free: free,
            locked: locked + freeze,
            source: BalanceSource.earn,
          );
        })
        .where((b) => b.total > 0 && b.symbol.isNotEmpty)
        .toList();
  }

  // ============ Futures 细分 ============

  Future<List<Balance>> _fetchUsdtMFutures(
      String apiKey, String apiSecret) async {
    // GET /fapi/v2/balance
    final data = await _signedGet(
      host: _fapiBase,
      path: '/fapi/v2/balance',
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
    if (data is! List) return <Balance>[];
    return data
        .map((item) {
          final asset = item['asset']?.toString() ?? '';
          final balance =
              double.tryParse(item['balance']?.toString() ?? '0') ?? 0;
          final unpnl =
              double.tryParse(item['crossUnPnl']?.toString() ?? '0') ?? 0;
          final total = balance + unpnl; // 钱包净值 = 余额 + 未实现盈亏
          return Balance(
            symbol: asset,
            total: total,
            free: total,
            locked: 0,
            source: BalanceSource.futures,
          );
        })
        .where((b) => b.total > 0 && b.symbol.isNotEmpty)
        .toList();
  }

  Future<List<Balance>> _fetchCoinMFutures(
      String apiKey, String apiSecret) async {
    // GET /dapi/v1/balance
    final data = await _signedGet(
      host: _dapiBase,
      path: '/dapi/v1/balance',
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
    if (data is! List) return <Balance>[];
    return data
        .map((item) {
          final asset = item['asset']?.toString() ?? '';
          final balance =
              double.tryParse(item['balance']?.toString() ?? '0') ?? 0;
          final unpnl =
              double.tryParse(item['crossUnPnl']?.toString() ?? '0') ?? 0;
          final total = balance + unpnl;
          return Balance(
            symbol: asset,
            total: total,
            free: total,
            locked: 0,
            source: BalanceSource.futures,
          );
        })
        .where((b) => b.total > 0 && b.symbol.isNotEmpty)
        .toList();
  }

  // ============ HTTP helper ============

  /// 签名 GET，返回已解析的 JSON（Map 或 List）
  Future<dynamic> _signedGet({
    required String host,
    required String path,
    required String apiKey,
    required String apiSecret,
    Map<String, String> params = const {},
  }) async {
    return _signedRequest(
      host: host,
      path: path,
      method: 'GET',
      apiKey: apiKey,
      apiSecret: apiSecret,
      params: params,
    );
  }

  Future<dynamic> _signedRequest({
    required String host,
    required String path,
    required String method,
    required String apiKey,
    required String apiSecret,
    Map<String, String> params = const {},
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final allParams = <String, String>{
      ...params,
      'timestamp': timestamp,
      'recvWindow': '10000',
    };
    final qs = allParams.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final sig = _sign(qs, apiSecret);
    final finalQs = '$qs&signature=$sig';

    final uri = Uri.parse('$host$path?$finalQs');
    final headers = {'X-MBX-APIKEY': apiKey};

    http.Response response;
    if (method == 'POST') {
      response = await http.post(uri, headers: headers).timeout(_timeout);
    } else {
      response = await http.get(uri, headers: headers).timeout(_timeout);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ExchangeAuthException(
        exchangeId: exchangeId,
        message: 'Invalid API credentials',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode != 200) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, Ticker>> getTickers(List<String> symbols) async {
    // 计算需要的 raw symbols（BTCUSDT 形式）
    final symbolSet =
        symbols.map((s) => s.replaceAll('/', '').toUpperCase()).toSet();

    // 优化：只请求需要的 symbols；空列表时才拉全量
    Uri uri;
    if (symbolSet.isEmpty) {
      uri = Uri.parse('$baseUrl/api/v3/ticker/24hr');
    } else {
      // Binance 接受 symbols=["BTCUSDT","ETHUSDT"] JSON 数组字符串
      final encoded = jsonEncode(symbolSet.toList());
      uri = Uri.parse('$baseUrl/api/v3/ticker/24hr')
          .replace(queryParameters: {'symbols': encoded});
    }

    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'Failed to fetch tickers: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    final list =
        decoded is List ? decoded : <dynamic>[]; // 单 symbol 时 Binance 会返回对象，这里统一兜底
    final result = <String, Ticker>{};

    for (final item in list) {
      final rawSymbol = item['symbol'] as String? ?? '';
      if (symbolSet.isNotEmpty && !symbolSet.contains(rawSymbol)) continue;

      // 转换 BTCUSDT -> BTC/USDT 格式
      String? formatted;
      if (rawSymbol.endsWith('USDT')) {
        formatted =
            '${rawSymbol.substring(0, rawSymbol.length - 4)}/USDT';
      } else if (rawSymbol.endsWith('BTC')) {
        formatted =
            '${rawSymbol.substring(0, rawSymbol.length - 3)}/BTC';
      }
      if (formatted == null) continue;

      final lastPrice =
          double.tryParse(item['lastPrice']?.toString() ?? '') ?? 0;
      final change =
          double.tryParse(item['priceChangePercent']?.toString() ?? '');

      result[formatted] = Ticker(
        symbol: formatted,
        lastPrice: lastPrice,
        change24h: change,
      );
    }

    return result;
  }
}
