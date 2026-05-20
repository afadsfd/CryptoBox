import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/exchanges/models/balance.dart';

void main() {
  test('BalanceSource uses stable storage keys', () {
    expect(BalanceSource.earnFlexible.storageKey, 'earn_flexible');
    expect(BalanceSource.futuresUsdt.storageKey, 'futures_usdt');
    expect(BalanceSource.unified.storageKey, 'unified');
  });

  test('BalanceSource parser keeps old and new values readable', () {
    expect(balanceSourceFromStorage('earn'), BalanceSource.earn);
    expect(balanceSourceFromStorage('futures'), BalanceSource.futures);
    expect(balanceSourceFromStorage('earn_flexible'), BalanceSource.earnFlexible);
    expect(balanceSourceFromStorage('futuresUsdt'), BalanceSource.futuresUsdt);
    expect(balanceSourceFromStorage('missing'), BalanceSource.spot);
  });
}
