import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exchange_service.dart';

/// 交易所服务全局 Provider
final exchangeServiceProvider = Provider<ExchangeService>((ref) {
  return ExchangeService();
});
