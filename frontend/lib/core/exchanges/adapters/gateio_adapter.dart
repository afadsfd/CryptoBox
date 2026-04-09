import 'dart:convert';

import 'package:crypto/crypto.dart';
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
          );
        })
        .where((b) => b.total > 0)
        .toList();
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
