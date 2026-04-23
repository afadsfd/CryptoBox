import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/balance.dart';
import '../models/ticker.dart';
import 'base_adapter.dart';

/// Coinbase Advanced Trade API 适配器
class CoinbaseAdapter extends BaseExchangeAdapter {
  static const _timeout = Duration(seconds: 15);

  @override
  String get exchangeId => 'coinbase';

  @override
  String get baseUrl => 'https://api.coinbase.com';

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
    required String method,
    required String path,
    String body = '',
  }) {
    final signPayload = '$timestamp$method$path$body';
    final signature = _sign(signPayload, apiSecret);

    return {
      'CB-ACCESS-KEY': apiKey,
      'CB-ACCESS-SIGN': signature,
      'CB-ACCESS-TIMESTAMP': timestamp,
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
    const path = '/api/v3/brokerage/accounts';
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    final headers = _buildHeaders(
      apiKey: apiKey,
      apiSecret: apiSecret,
      timestamp: timestamp,
      method: 'GET',
      path: path,
    );

    final uri = Uri.parse('$baseUrl$path');
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
    final accounts = data['accounts'] as List<dynamic>? ?? [];

    final balances = <Balance>[];

    for (final account in accounts) {
      final currency = account['currency'] as String? ?? '';
      final availableBalance =
          account['available_balance'] as Map<String, dynamic>? ?? {};
      final value =
          double.tryParse(availableBalance['value']?.toString() ?? '0') ?? 0;

      // Coinbase 只提供 available balance
      // 注：此接口已覆盖现货 + 质押 + 赚币等所有 Coinbase 账户类型
      if (value > 0) {
        balances.add(Balance(
          symbol: currency,
          total: value,
          free: value,
          locked: 0,
          source: BalanceSource.spot,
        ));
      }
    }

    return balances;
  }

  /// Coinbase 的 `/api/v3/brokerage/accounts` 已覆盖现货 + 质押 + 赚币等所有账户，
  /// 因此不单独实现 earn/futures，沿用 base 的空默认。
  /// Coinbase Advanced Trade 目前没有独立的期货账户公开 API。

  @override
  Future<Map<String, Ticker>> getTickers(List<String> symbols) async {
    // 并发拉取所有 ticker（原实现串行，N 个 symbol 需要 N × RTT）
    final futures = symbols.map<Future<MapEntry<String, Ticker>?>>(
      (symbol) async {
        final productId = symbol.replaceAll('/', '-');
        final uri = Uri.parse('$baseUrl/api/v3/brokerage/products/$productId');
        try {
          final response = await http.get(uri).timeout(_timeout);
          if (response.statusCode != 200) return null;
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final lastPrice =
              double.tryParse(data['price']?.toString() ?? '') ?? 0;
          final change = double.tryParse(
              data['price_percentage_change_24h']?.toString() ?? '');
          return MapEntry(
            symbol,
            Ticker(
              symbol: symbol,
              lastPrice: lastPrice,
              change24h: change,
            ),
          );
        } catch (_) {
          return null;
        }
      },
    );

    final entries = await Future.wait(futures);
    return {
      for (final e in entries)
        if (e != null) e.key: e.value,
    };
  }
}
