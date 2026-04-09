import 'adapters/base_adapter.dart';
import 'adapters/binance_adapter.dart';
import 'adapters/okx_adapter.dart';
import 'adapters/bybit_adapter.dart';
import 'adapters/coinbase_adapter.dart';
import 'adapters/gateio_adapter.dart';
import 'adapters/bitget_adapter.dart';

/// 交易所统一服务入口
class ExchangeService {
  final Map<String, BaseExchangeAdapter> _adapters = {};

  ExchangeService() {
    _adapters['binance'] = BinanceAdapter();
    _adapters['okx'] = OkxAdapter();
    _adapters['bybit'] = BybitAdapter();
    _adapters['coinbase'] = CoinbaseAdapter();
    _adapters['gateio'] = GateioAdapter();
    _adapters['bitget'] = BitgetAdapter();
  }

  /// 根据交易所 ID 获取适配器
  BaseExchangeAdapter? getAdapter(String exchangeId) {
    return _adapters[exchangeId];
  }

  /// 支持的交易所 ID 列表
  List<String> get supportedExchangeIds => _adapters.keys.toList();
}
