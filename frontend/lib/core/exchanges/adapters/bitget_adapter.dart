import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/balance.dart';
import '../models/ticker.dart';
import 'base_adapter.dart';

/// Bitget 交易所适配器
class BitgetAdapter extends BaseExchangeAdapter {
  static const _timeout = Duration(seconds: 15);

  @override
  String get exchangeId => 'bitget';

  @override
  String get baseUrl => 'https://api.bitget.com';

  /// Bitget 签名: HMAC-SHA256 -> Base64
  String _sign(String message, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(message));
    return base64.encode(digest.bytes);
  }

  Map<String, String> _buildHeaders({
    required String apiKey,
    required String apiSecret,
    required String passphrase,
    required String timestamp,
    required String method,
    required String path,
    String body = '',
  }) {
    final signPayload = '$timestamp$method$path$body';
    final signature = _sign(signPayload, apiSecret);

    return {
      'ACCESS-KEY': apiKey,
      'ACCESS-SIGN': signature,
      'ACCESS-TIMESTAMP': timestamp,
      'ACCESS-PASSPHRASE': passphrase,
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
    const path = '/api/v2/spot/account/assets';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

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

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    // 检查 Bitget 业务错误码
    final code = responseData['code']?.toString() ?? '';
    if (code != '00000') {
      final msg = responseData['msg'] ?? 'Unknown error';
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'Bitget error $code: $msg',
      );
    }

    final data = responseData['data'] as List<dynamic>? ?? [];

    return data
        .map((item) {
          final available =
              double.tryParse(item['available']?.toString() ?? '0') ?? 0;
          final frozen =
              double.tryParse(item['frozen']?.toString() ?? '0') ?? 0;
          return Balance(
            symbol: item['coin'] as String? ?? '',
            total: available + frozen,
            free: available,
            locked: frozen,
          );
        })
        .where((b) => b.total > 0)
        .toList();
  }

  @override
  Future<Map<String, Ticker>> getTickers(List<String> symbols) async {
    final uri = Uri.parse('$baseUrl/api/v2/spot/market/tickers');
    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ExchangeApiException(
        exchangeId: exchangeId,
        message: 'Failed to fetch tickers: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final data = responseData['data'] as List<dynamic>? ?? [];

    final result = <String, Ticker>{};

    // Bitget 使用 BTCUSDT 格式
    final symbolSet =
        symbols.map((s) => s.replaceAll('/', '').toUpperCase()).toSet();

    for (final item in data) {
      final rawSymbol = item['symbol'] as String? ?? '';
      if (symbolSet.isNotEmpty && !symbolSet.contains(rawSymbol.toUpperCase())) {
        continue;
      }

      // 转换 BTCUSDT -> BTC/USDT
      String? formatted;
      if (rawSymbol.toUpperCase().endsWith('USDT')) {
        formatted =
            '${rawSymbol.substring(0, rawSymbol.length - 4)}/USDT';
      }
      if (formatted == null) continue;

      final lastPrice =
          double.tryParse(item['lastPr']?.toString() ?? '') ?? 0;
      final change =
          double.tryParse(item['change24h']?.toString() ?? '');

      // Bitget change24h 是小数形式 (0.05 = 5%)，转为百分比
      final changePct = change != null ? change * 100 : null;

      result[formatted] = Ticker(
        symbol: formatted,
        lastPrice: lastPrice,
        change24h: changePct,
      );
    }

    return result;
  }
}
