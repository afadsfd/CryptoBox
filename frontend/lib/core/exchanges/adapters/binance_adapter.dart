import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/balance.dart';
import '../models/ticker.dart';
import 'base_adapter.dart';

/// Binance 交易所适配器
class BinanceAdapter extends BaseExchangeAdapter {
  static const _timeout = Duration(seconds: 15);

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
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final queryString = 'timestamp=$timestamp';
    final signature = _sign(queryString, apiSecret);

    final uri = Uri.parse(
      '$baseUrl/api/v3/account?$queryString&signature=$signature',
    );

    final response = await http
        .get(uri, headers: {'X-MBX-APIKEY': apiKey}).timeout(_timeout);

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
    final balances = data['balances'] as List<dynamic>? ?? [];

    return balances
        .map((b) {
          final free = double.tryParse(b['free']?.toString() ?? '0') ?? 0;
          final locked =
              double.tryParse(b['locked']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: b['asset'] as String,
            total: free + locked,
            free: free,
            locked: locked,
          );
        })
        .where((b) => b.total > 0)
        .toList();
  }

  @override
  Future<Map<String, Ticker>> getTickers(List<String> symbols) async {
    final uri = Uri.parse('$baseUrl/api/v3/ticker/24hr');
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

    final symbolSet =
        symbols.map((s) => s.replaceAll('/', '').toUpperCase()).toSet();

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
