import '../models/balance.dart';
import '../models/ticker.dart';

/// 交易所适配器抽象基类
abstract class BaseExchangeAdapter {
  /// 交易所标识符，如 binance, okx
  String get exchangeId;

  /// API 基础 URL
  String get baseUrl;

  /// 验证 API 连接是否有效
  Future<bool> verifyConnection({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  });

  /// 获取现货账户余额（过滤零余额）
  Future<List<Balance>> getSpotBalance({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  });

  /// 获取行情 ticker 数据
  Future<Map<String, Ticker>> getTickers(List<String> symbols);
}

/// 交易所 API 异常
class ExchangeApiException implements Exception {
  final String exchangeId;
  final String message;
  final int? statusCode;

  ExchangeApiException({
    required this.exchangeId,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() =>
      'ExchangeApiException($exchangeId): $message (status: $statusCode)';
}

/// 交易所认证异常
class ExchangeAuthException extends ExchangeApiException {
  ExchangeAuthException({
    required super.exchangeId,
    required super.message,
    super.statusCode,
  });
}
