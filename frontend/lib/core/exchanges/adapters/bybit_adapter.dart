import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/balance.dart';
import '../models/ticker.dart';
import 'base_adapter.dart';

/// Bybit 交易所适配器
///
/// 说明：UNIFIED 账户一张表已包含现货+衍生品的保证金/净值，
/// 因此 getSpotBalance 的结果已覆盖合约。理财（Earn）和资金账户
/// (FUND) 需要单独接口。
class BybitAdapter extends BaseExchangeAdapter {
  static const _timeout = Duration(seconds: 15);
  static const _recvWindow = '5000';

  @override
  String get exchangeId => 'bybit';

  @override
  String get baseUrl => 'https://api.bybit.com';

  /// HMAC-SHA256 签名
  String _sign(String message, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(message));
    return digest.toString();
  }

  Map<String, String> _buildHeaders({
    required String apiKey,
    required String apiSecret,
    required String timestamp,
    required String queryString,
  }) {
    // 签名内容: timestamp + apiKey + recvWindow + queryString
    final signPayload = '$timestamp$apiKey$_recvWindow$queryString';
    final signature = _sign(signPayload, apiSecret);

    return {
      'X-BAPI-API-KEY': apiKey,
      'X-BAPI-SIGN': signature,
      'X-BAPI-TIMESTAMP': timestamp,
      'X-BAPI-RECV-WINDOW': _recvWindow,
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
    const queryString = 'accountType=UNIFIED';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final headers = _buildHeaders(
      apiKey: apiKey,
      apiSecret: apiSecret,
      timestamp: timestamp,
      queryString: queryString,
    );

    final uri = Uri.parse(
      '$baseUrl/v5/account/wallet-balance?$queryString',
    );
    final response = await http.get(uri, headers: headers).timeout(_timeout);

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

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // 检查 Bybit 业务错误码
    final retCode = data['retCode'] as int? ?? -1;
    if (retCode != 0) {
      final retMsg = data['retMsg'] ?? 'Unknown error';
      if (retCode == 10003 || retCode == 10004) {
        throw ExchangeAuthException(
          exchangeId: exchangeId,
          message: 'Auth error: $retMsg',
        );
      }
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'Bybit error $retCode: $retMsg',
      );
    }

    final result = data['result'] as Map<String, dynamic>? ?? {};
    final list = result['list'] as List<dynamic>? ?? [];

    if (list.isEmpty) return [];

    final coins =
        (list[0] as Map<String, dynamic>)['coin'] as List<dynamic>? ?? [];

    return coins
        .map((c) {
          final walletBalance =
              double.tryParse(c['walletBalance']?.toString() ?? '0') ?? 0;
          final locked =
              double.tryParse(c['locked']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: c['coin'] as String? ?? '',
            total: walletBalance,
            free: walletBalance - locked,
            locked: locked,
            source: BalanceSource.spot,
          );
        })
        .where((b) => b.total > 0)
        .toList();
  }

  /// Bybit UNIFIED 已包含合约，此处返回空
  @override
  Future<List<Balance>> getFuturesBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async =>
      <Balance>[];

  /// Bybit 理财：资金账户（FUND）+ Earn 仓位
  @override
  Future<List<Balance>> getEarnBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) async {
    final results = <Balance>[];

    // 1) 资金账户 FUND
    try {
      final fund = await _fetchFundBalance(apiKey, apiSecret);
      results.addAll(fund);
    } catch (e) {
      debugPrint('[Bybit] FUND balance failed: $e');
    }

    return mergeBalances(results);
  }

  Future<List<Balance>> _fetchFundBalance(
      String apiKey, String apiSecret) async {
    const queryString = 'accountType=FUND';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final headers = _buildHeaders(
      apiKey: apiKey,
      apiSecret: apiSecret,
      timestamp: timestamp,
      queryString: queryString,
    );
    final uri = Uri.parse(
      '$baseUrl/v5/asset/transfer/query-account-coins-balance?$queryString',
    );
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    if (response.statusCode != 200) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final retCode = data['retCode'] as int? ?? -1;
    if (retCode != 0) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'Bybit error $retCode: ${data['retMsg']}',
      );
    }
    final result = data['result'] as Map<String, dynamic>? ?? {};
    final balances = result['balance'] as List<dynamic>? ?? [];
    return balances
        .map((b) {
          final walletBalance = double.tryParse(
                  b['walletBalance']?.toString() ?? '0') ??
              0;
          final transfer = double.tryParse(
                  b['transferBalance']?.toString() ?? '0') ??
              0;
          final total = walletBalance > 0 ? walletBalance : transfer;
          return Balance(
            symbol: b['coin']?.toString() ?? '',
            total: total,
            free: transfer,
            locked: total - transfer > 0 ? total - transfer : 0,
            source: BalanceSource.earn,
          );
        })
        .where((b) => b.total > 0 && b.symbol.isNotEmpty)
        .toList();
  }

  @override
  Future<Map<String, Ticker>> getTickers(List<String> symbols) async {
    final uri = Uri.parse(
      '$baseUrl/v5/market/tickers?category=spot',
    );

    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'Failed to fetch tickers: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>? ?? {};
    final list = result['list'] as List<dynamic>? ?? [];

    final tickers = <String, Ticker>{};
    final symbolSet =
        symbols.map((s) => s.replaceAll('/', '').toUpperCase()).toSet();

    for (final item in list) {
      final rawSymbol = item['symbol'] as String? ?? '';
      if (symbolSet.isNotEmpty && !symbolSet.contains(rawSymbol)) continue;

      // 转换 BTCUSDT -> BTC/USDT
      String? formatted;
      if (rawSymbol.endsWith('USDT')) {
        formatted =
            '${rawSymbol.substring(0, rawSymbol.length - 4)}/USDT';
      }
      if (formatted == null) continue;

      final lastPrice =
          double.tryParse(item['lastPrice']?.toString() ?? '') ?? 0;
      final prevPrice =
          double.tryParse(item['prevPrice24h']?.toString() ?? '') ?? 0;

      double? change24h;
      if (prevPrice > 0) {
        change24h = ((lastPrice - prevPrice) / prevPrice) * 100;
      }

      tickers[formatted] = Ticker(
        symbol: formatted,
        lastPrice: lastPrice,
        change24h: change24h,
      );
    }

    return tickers;
  }
}
