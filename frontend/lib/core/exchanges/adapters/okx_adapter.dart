import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/balance.dart';
import '../models/ticker.dart';
import 'base_adapter.dart';

/// OKX 交易所适配器
///
/// 说明：OKX 的统一交易账户（Unified Trading Account）一张表已经同时包含
/// 现货、合约、杠杆、期权的保证金与净值，因此现货方法的结果已覆盖合约账户。
/// 理财（活期/定期 Savings）属于资金账户 + 金融产品，需要额外接口获取。
class OkxAdapter extends BaseExchangeAdapter {
  static const _timeout = Duration(seconds: 15);

  @override
  String get exchangeId => 'okx';

  @override
  String get baseUrl => 'https://www.okx.com';

  /// OKX 签名: HMAC-SHA256 -> Base64
  String _sign(String message, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(message));
    return base64.encode(digest.bytes);
  }

  /// ISO 8601 UTC 时间戳
  String _getTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  Map<String, String> _buildHeaders({
    required String apiKey,
    required String apiSecret,
    required String passphrase,
    required String timestamp,
    required String method,
    required String path,
  }) {
    final signPayload = '$timestamp$method$path';
    final signature = _sign(signPayload, apiSecret);

    return {
      'OK-ACCESS-KEY': apiKey,
      'OK-ACCESS-SIGN': signature,
      'OK-ACCESS-TIMESTAMP': timestamp,
      'OK-ACCESS-PASSPHRASE': passphrase,
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
      await getSpotBalance(
        apiKey: apiKey,
        apiSecret: apiSecret,
        passphrase: passphrase,
      );
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
    const path = '/api/v5/account/balance';
    final timestamp = _getTimestamp();

    final headers = _buildHeaders(
      apiKey: apiKey,
      apiSecret: apiSecret,
      passphrase: passphrase ?? '',
      timestamp: timestamp,
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

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final dataList = data['data'] as List<dynamic>? ?? [];

    if (dataList.isEmpty) return [];

    final details =
        (dataList[0] as Map<String, dynamic>)['details'] as List<dynamic>? ??
            [];

    return details
        .map((d) {
          final availBal =
              double.tryParse(d['availBal']?.toString() ?? '0') ?? 0;
          final frozenBal =
              double.tryParse(d['frozenBal']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: d['ccy'] as String? ?? '',
            total: availBal + frozenBal,
            free: availBal,
            locked: frozenBal,
            source: BalanceSource.spot,
          );
        })
        .where((b) => b.total > 0)
        .toList();
  }

  /// OKX 统一账户已包含合约，无需单独获取
  @override
  Future<List<Balance>> getFuturesBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async =>
      <Balance>[];

  /// OKX 理财（活期 Savings + 资金账户 + 结构化产品）
  @override
  Future<List<Balance>> getEarnBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    // 1) 活期/定期 Savings  &  2) 资金账户 —— 并发拉取
    final pp = passphrase ?? '';
    final results = await Future.wait([
      _fetchSavings(apiKey, apiSecret, pp).catchError((e) {
        debugPrint('[OKX] savings failed: $e');
        return <Balance>[];
      }),
      _fetchFunding(apiKey, apiSecret, pp).catchError((e) {
        debugPrint('[OKX] funding failed: $e');
        return <Balance>[];
      }),
    ]);

    return mergeBalances(results.expand((b) => b).toList());
  }

  Future<List<Balance>> _fetchSavings(
      String apiKey, String apiSecret, String passphrase) async {
    const path = '/api/v5/finance/savings/balance';
    final response = await _signedGet(apiKey, apiSecret, passphrase, path);
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) {
          final amt =
              double.tryParse(item['amt']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: item['ccy']?.toString() ?? '',
            total: amt,
            free: 0,
            locked: amt,
            source: BalanceSource.earn,
          );
        })
        .where((b) => b.total > 0 && b.symbol.isNotEmpty)
        .toList();
  }

  Future<List<Balance>> _fetchFunding(
      String apiKey, String apiSecret, String passphrase) async {
    const path = '/api/v5/asset/balances';
    final response = await _signedGet(apiKey, apiSecret, passphrase, path);
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) {
          final bal =
              double.tryParse(item['bal']?.toString() ?? '0') ?? 0;
          final frozen =
              double.tryParse(item['frozenBal']?.toString() ?? '0') ?? 0;
          final avail =
              double.tryParse(item['availBal']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: item['ccy']?.toString() ?? '',
            total: bal > 0 ? bal : (avail + frozen),
            free: avail,
            locked: frozen,
            source: BalanceSource.earn,
          );
        })
        .where((b) => b.total > 0 && b.symbol.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _signedGet(
    String apiKey,
    String apiSecret,
    String passphrase,
    String path,
  ) async {
    final timestamp = _getTimestamp();
    final headers = _buildHeaders(
      apiKey: apiKey,
      apiSecret: apiSecret,
      passphrase: passphrase,
      timestamp: timestamp,
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
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, Ticker>> getTickers(List<String> symbols) async {
    final result = <String, Ticker>{};

    // OKX uses instId format like BTC-USDT
    for (final symbol in symbols) {
      final instId = symbol.replaceAll('/', '-');
      final uri = Uri.parse(
        '$baseUrl/api/v5/market/ticker?instId=$instId',
      );

      try {
        final response = await http.get(uri).timeout(_timeout);
        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = data['data'] as List<dynamic>? ?? [];
        if (dataList.isEmpty) continue;

        final item = dataList[0] as Map<String, dynamic>;
        final lastPrice =
            double.tryParse(item['last']?.toString() ?? '') ?? 0;

        // 计算 24h 涨跌
        final open24h =
            double.tryParse(item['open24h']?.toString() ?? '') ?? 0;
        double? change24h;
        if (open24h > 0) {
          change24h = ((lastPrice - open24h) / open24h) * 100;
        }

        result[symbol] = Ticker(
          symbol: symbol,
          lastPrice: lastPrice,
          change24h: change24h,
        );
      } catch (_) {
        continue;
      }
    }

    return result;
  }
}
