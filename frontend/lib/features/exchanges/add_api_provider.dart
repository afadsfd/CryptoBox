import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exchanges/exchange_provider.dart';
import '../../core/exchanges/exchange_service.dart';
import '../../core/exchanges/models/exchange_info.dart';
import '../../core/local_storage/database.dart';
import '../../core/local_storage/database_provider.dart';
import '../../core/local_storage/repositories/exchange_repository.dart';
import '../../core/security/key_manager.dart';
import '../../core/security/security_provider.dart';
import '../portfolio/portfolio_provider.dart';
import '../portfolio/portfolio_service.dart';
import 'exchanges_provider.dart';

/// Sentinel 值，用于区分 "未传参" 和 "显式传 null"
const _sentinel = Object();

/// 添加 API 页面状态
class AddApiState {
  final String exchangeId;
  final String? exchangeName;
  final String apiKey;
  final String apiSecret;
  final String passphrase;
  final String label;
  final bool isLoading;
  final bool isConnected;
  final String? error;

  const AddApiState({
    required this.exchangeId,
    this.exchangeName,
    this.apiKey = '',
    this.apiSecret = '',
    this.passphrase = '',
    this.label = '',
    this.isLoading = false,
    this.isConnected = false,
    this.error,
  });

  AddApiState copyWith({
    String? exchangeId,
    String? exchangeName,
    String? apiKey,
    String? apiSecret,
    String? passphrase,
    String? label,
    bool? isLoading,
    bool? isConnected,
    Object? error = _sentinel,
  }) {
    return AddApiState(
      exchangeId: exchangeId ?? this.exchangeId,
      exchangeName: exchangeName ?? this.exchangeName,
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      passphrase: passphrase ?? this.passphrase,
      label: label ?? this.label,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  /// 是否可以提交（API Key 和 Secret 不能为空）
  bool get canSubmit => apiKey.isNotEmpty && apiSecret.isNotEmpty && !isLoading;

  /// 是否需要 Passphrase
  bool get requiresPassphrase {
    final info = ExchangeInfo.supportedExchanges.where(
      (e) => e.id == exchangeId.toLowerCase(),
    );
    return info.isNotEmpty && info.first.requiresPassphrase;
  }

  /// 获取交易所 Logo 颜色
  String? get exchangeLogoColor {
    final exchangeColors = {
      'binance': '#F3BA2F',
      'bybit': '#000000',
      'okx': '#FFFFFF',
      'coinbase': '#0052FF',
      'gateio': '#2354E6',
      'bitget': '#00F0FF',
    };
    return exchangeColors[exchangeId.toLowerCase()];
  }

  /// 获取交易所 Logo 字母
  String get exchangeLogoLetter {
    final exchangeLetters = {
      'binance': 'B',
      'bybit': 'By',
      'okx': 'O',
      'coinbase': 'C',
      'gateio': 'G',
      'bitget': 'Bg',
    };
    return exchangeLetters[exchangeId.toLowerCase()] ??
        (exchangeId.isNotEmpty ? exchangeId.substring(0, 1).toUpperCase() : '?');
  }
}

String _generateAccountId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = Random.secure().nextInt(999999);
  return 'acct_${now}_$rand';
}

/// 添加 API 页面状态 Notifier — 本地验证+加密存储
class AddApiNotifier extends StateNotifier<AddApiState> {
  final Ref _ref;

  AddApiNotifier(this._ref, String exchangeId)
      : super(AddApiState(exchangeId: exchangeId)) {
    _initializeExchangeInfo();
  }

  ExchangeService get _exchangeService =>
      _ref.read(exchangeServiceProvider);

  KeyManager get _keyManager => _ref.read(keyManagerProvider);

  ExchangeRepository get _exchangeRepo =>
      _ref.read(exchangeRepositoryProvider);

  PortfolioService get _portfolioService =>
      _ref.read(portfolioServiceProvider);

  /// 初始化交易所信息
  void _initializeExchangeInfo() {
    final info = ExchangeInfo.supportedExchanges.where(
      (e) => e.id == state.exchangeId.toLowerCase(),
    );
    final name = info.isNotEmpty ? info.first.name : state.exchangeId.toUpperCase();
    state = state.copyWith(exchangeName: name);
  }

  /// 设置 API Key
  void setApiKey(String value) {
    state = state.copyWith(apiKey: value, error: null);
  }

  /// 设置 API Secret
  void setApiSecret(String value) {
    state = state.copyWith(apiSecret: value, error: null);
  }

  /// 设置 Passphrase
  void setPassphrase(String value) {
    state = state.copyWith(passphrase: value, error: null);
  }

  /// 设置 Label
  void setLabel(String value) {
    state = state.copyWith(label: value, error: null);
  }

  /// 提交连接 — 本地验证 + 加密存储 + 同步余额
  Future<bool> submitConnection() async {
    if (!state.canSubmit) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. 获取适配器并验证连接
      final adapter = _exchangeService.getAdapter(state.exchangeId);
      if (adapter == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unsupported exchange: ${state.exchangeId}',
        );
        return false;
      }

      final passphrase =
          state.requiresPassphrase && state.passphrase.isNotEmpty
              ? state.passphrase
              : null;

      final isValid = await adapter.verifyConnection(
        apiKey: state.apiKey,
        apiSecret: state.apiSecret,
        passphrase: passphrase,
      );

      if (!isValid) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid API credentials. Please check and try again.',
        );
        return false;
      }

      // 2. 加密凭证
      final encrypted = _keyManager.encryptCredentials(
        apiKey: state.apiKey,
        apiSecret: state.apiSecret,
        passphrase: passphrase,
      );

      // 3. 存入本地 DB
      final label = state.label.isNotEmpty
          ? state.label
          : '${state.exchangeName ?? state.exchangeId} Account';

      final accountId = _generateAccountId();

      await _exchangeRepo.upsert(ExchangeAccountsCompanion.insert(
        id: accountId,
        exchangeName: state.exchangeId,
        label: Value(label),
        encryptedApiKey: encrypted['apiKey']!,
        encryptedSecret: encrypted['apiSecret']!,
        encryptedPassphrase: Value(encrypted['passphrase']),
        isActive: const Value(true),
      ));

      // 4. 立即同步该交易所的余额
      try {
        await _portfolioService.syncSingleExchange(accountId);
      } catch (e) {
        debugPrint('Post-connect sync failed (non-blocking): $e');
      }

      state = state.copyWith(
        isLoading: false,
        isConnected: true,
        error: null,
      );

      // 刷新交易所列表
      await _ref.read(exchangesProvider.notifier).refreshConnectedExchanges();

      return true;
    } catch (e) {
      debugPrint('Failed to connect exchange: $e');
      String errorMsg;
      if (e.toString().contains('auth') ||
          e.toString().contains('Auth') ||
          e.toString().contains('401') ||
          e.toString().contains('invalid')) {
        errorMsg = 'Invalid API credentials. Please check and try again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('socket') ||
          e.toString().contains('timeout')) {
        errorMsg = 'Network error. Please check your connection.';
      } else {
        errorMsg = 'Failed to connect: ${e.toString()}';
      }
      state = state.copyWith(
        isLoading: false,
        isConnected: false,
        error: errorMsg,
      );
      return false;
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 重置状态
  void reset() {
    state = AddApiState(
      exchangeId: state.exchangeId,
      exchangeName: state.exchangeName,
    );
  }
}

/// 添加 API 页面状态 Provider（带参数）
final addApiProvider = StateNotifierProvider.family<AddApiNotifier, AddApiState, String>(
  (ref, exchangeId) => AddApiNotifier(ref, exchangeId),
);
