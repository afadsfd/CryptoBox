import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/balance.dart';
import '../models/ticker.dart';
import 'base_adapter.dart';

/// Gate.io 交易所适配器
class GateioAdapter extends BaseExchangeAdapter {
  static const _timeout = Duration(seconds: 15);

  @override
  String get exchangeId => 'gateio';

  @override
  String get baseUrl => 'https://api.gateio.ws';

  /// HMAC-SHA512 签名
  String _sign(String message, String secret) {
    final hmac = Hmac(sha512, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(message));
    return digest.toString();
  }

  /// SHA-512 hash
  String _sha512Hash(String data) {
    final digest = sha512.convert(utf8.encode(data));
    return digest.toString();
  }

  Map<String, String> _buildHeaders({
    required String apiKey,
    required String apiSecret,
    required String method,
    required String path,
    String query = '',
    String body = '',
  }) {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final bodyHash = _sha512Hash(body);

    // 签名内容: METHOD\nPATH\nQUERY\nBODY_HASH\nTIMESTAMP
    final signPayload = '$method\n$path\n$query\n$bodyHash\n$timestamp';
    final signature = _sign(signPayload, apiSecret);

    return {
      'KEY': apiKey,
      'SIGN': signature,
      'Timestamp': timestamp,
      'Content-Type': 'application/json',
    };
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
    const path = '/api/v4/spot/accounts';

    final headers = _buildHeaders(
      apiKey: apiKey,
      apiSecret: apiSecret,
      method: 'GET',
      path: path,
    );

    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: headers).timeout(_timeout);

    if (response.statusCode == 401) {
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

    final list = jsonDecode(response.body) as List<dynamic>;

    return list
        .map((item) {
          final available =
              double.tryParse(item['available']?.toString() ?? '0') ?? 0;
          final locked =
              double.tryParse(item['locked']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: item['currency'] as String? ?? '',
            total: available + locked,
            free: available,
            locked: locked,
            source: BalanceSource.spot,
          );
        })
        .where((b) => b.total > 0)
        .toList();
  }

  /// Gate.io 合约账户：U 本位 + BTC 本位
  @override
  Future<List<Balance>> getFuturesBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    final results = <Balance>[];
    for (final settle in ['usdt', 'btc']) {
      try {
        final f = await _fetchFutures(apiKey, apiSecret, settle);
        results.addAll(f);
      } catch (e) {
        debugPrint('[Gate.io] futures $settle failed: $e');
      }
    }
    return mergeBalancesBySource(results);
  }

  Future<List<Balance>> _fetchFutures(
      String apiKey, String apiSecret, String settle) async {
    final path = '/api/v4/futures/$settle/accounts';
    final headers = _buildHeaders(
      apiKey: apiKey,
      apiSecret: apiSecret,
      method: 'GET',
      path: path,
    );
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    if (response.statusCode != 200) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }
    final data = jsonDecode(response.body);
    if (data is! Map) return <Balance>[];
    final currency = data['currency']?.toString() ?? settle.toUpperCase();
    final total = double.tryParse(data['total']?.toString() ?? '0') ?? 0;
    final unrealisedPnl =
        double.tryParse(data['unrealised_pnl']?.toString() ?? '0') ?? 0;
    final available =
        double.tryParse(data['available']?.toString() ?? '0') ?? 0;
    final net = total + unrealisedPnl;
    if (net <= 0) return <Balance>[];
    final source =
        settle == 'usdt' ? BalanceSource.futuresUsdt : BalanceSource.futuresCoin;
    return [
      Balance(
        symbol: currency,
        total: net,
        free: available,
        locked: net - available > 0 ? net - available : 0,
        source: source,
      ),
    ];
  }

  /// Gate.io 理财：理财 / 借贷余额
  @override
  Future<List<Balance>> getEarnBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    // Gate.io 的理财接口较为分散（结构化、双币、借贷等），
    // 优先拉取统一账户的总览余额作为补充。
    try {
      const path = '/api/v4/wallet/total_balance';
      final headers = _buildHeaders(
        apiKey: apiKey,
        apiSecret: apiSecret,
        method: 'GET',
        path: path,
      );
      final uri = Uri.parse('$baseUrl$path');
      final response =
          await http.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode != 200) return <Balance>[];
      // 此接口只返回总价值估算（USDT），不返回各币种明细，无法按币种入账。
      // 保留为诊断用，不计入 getAllBalances。
      return <Balance>[];
    } catch (e) {
      debugPrint('[Gate.io] earn failed: $e');
      return <Balance>[];
    }
  }

  @override
  Future<Map<String, Ticker>> getTickers(List<String> symbols) async {
    final uri = Uri.parse('$baseUrl/api/v4/spot/tickers');
    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'Failed to fetch tickers: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    final result = <String, Ticker>{};

    // Gate.io 使用 BTC_USDT 格式
    final symbolSet = <String>{};
    for (final s in symbols) {
      symbolSet.add(s.replaceAll('/', '_').toUpperCase());
    }

    for (final item in list) {
      final rawPair = item['currency_pair'] as String? ?? '';
      if (symbolSet.isNotEmpty && !symbolSet.contains(rawPair.toUpperCase())) {
        continue;
      }

      // 转换 BTC_USDT -> BTC/USDT
      final formatted = rawPair.replaceAll('_', '/');
      final lastPrice =
          double.tryParse(item['last']?.toString() ?? '') ?? 0;
      final change =
          double.tryParse(item['change_percentage']?.toString() ?? '');

      result[formatted] = Ticker(
        symbol: formatted,
        lastPrice: lastPrice,
        change24h: change,
      );
    }

    return result;
  }
}
