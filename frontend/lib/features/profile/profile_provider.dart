import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/local_storage/database_provider.dart';
import '../../core/local_storage/repositories/exchange_repository.dart';
import '../../core/security/key_manager.dart';
import '../../core/security/security_provider.dart';

/// copyWith 未传 error 时保留原值（区别于默认 null）
const Object _profileStateKeepError = Object();

/// 已连接的 API 信息
class ConnectedApi {
  final String id;
  final String name;
  final String exchange;
  final String lastActive;
  final bool isActive;

  const ConnectedApi({
    required this.id,
    required this.name,
    required this.exchange,
    required this.lastActive,
    this.isActive = true,
  });
}

/// 用户偏好设置
class UserPreferences {
  final String baseCurrency;
  final int refreshIntervalMinutes;
  final bool biometricEnabled;
  final bool marketAlertsEnabled;

  const UserPreferences({
    this.baseCurrency = 'USD',
    this.refreshIntervalMinutes = 5,
    this.biometricEnabled = true,
    this.marketAlertsEnabled = true,
  });

  UserPreferences copyWith({
    String? baseCurrency,
    int? refreshIntervalMinutes,
    bool? biometricEnabled,
    bool? marketAlertsEnabled,
  }) {
    return UserPreferences(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      refreshIntervalMinutes: refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      marketAlertsEnabled: marketAlertsEnabled ?? this.marketAlertsEnabled,
    );
  }
}

/// Profile 状态（本地化：无用户概念）
class ProfileState {
  final UserPreferences preferences;
  final List<ConnectedApi> connectedApis;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.preferences = const UserPreferences(),
    this.connectedApis = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserPreferences? preferences,
    List<ConnectedApi>? connectedApis,
    bool? isLoading,
    Object? error = _profileStateKeepError,
  }) {
    return ProfileState(
      preferences: preferences ?? this.preferences,
      connectedApis: connectedApis ?? this.connectedApis,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _profileStateKeepError)
          ? this.error
          : error as String?,
    );
  }
}

/// SharedPreferences keys
const _prefBaseCurrency = 'pref_base_currency';
const _prefRefreshInterval = 'pref_refresh_interval';
const _prefBiometricEnabled = 'pref_biometric_enabled';
const _prefMarketAlerts = 'pref_market_alerts';

/// Profile State Notifier — 本地化版本
class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState()) {
    _loadProfile();
  }

  ExchangeRepository get _exchangeRepo =>
      _ref.read(exchangeRepositoryProvider);

  KeyManager get _keyManager => _ref.read(keyManagerProvider);

  Future<void> _loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. 加载偏好设置（SharedPreferences）
      final prefs = await SharedPreferences.getInstance();
      final preferences = UserPreferences(
        baseCurrency: prefs.getString(_prefBaseCurrency) ?? 'USD',
        refreshIntervalMinutes: prefs.getInt(_prefRefreshInterval) ?? 5,
        biometricEnabled: prefs.getBool(_prefBiometricEnabled) ?? true,
        marketAlertsEnabled: prefs.getBool(_prefMarketAlerts) ?? true,
      );

      // 2. 加载已连接 API 列表（从本地 DB）
      final accounts = await _exchangeRepo.getAllAccounts();
      final connectedApis = accounts.map((acct) {
        final lastActive = acct.lastSyncAt != null
            ? _formatRelativeTime(acct.lastSyncAt!)
            : 'Never synced';
        return ConnectedApi(
          id: acct.id,
          name: acct.label.isNotEmpty ? acct.label : acct.exchangeName,
          exchange: acct.exchangeName,
          lastActive: lastActive,
          isActive: acct.isActive,
        );
      }).toList();

      state = state.copyWith(
        preferences: preferences,
        connectedApis: connectedApis,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// 更新偏好设置（保存到 SharedPreferences）
  Future<void> updatePreferences(UserPreferences newPreferences) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBaseCurrency, newPreferences.baseCurrency);
      await prefs.setInt(_prefRefreshInterval, newPreferences.refreshIntervalMinutes);
      await prefs.setBool(_prefBiometricEnabled, newPreferences.biometricEnabled);
      await prefs.setBool(_prefMarketAlerts, newPreferences.marketAlertsEnabled);

      state = state.copyWith(
        preferences: newPreferences,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('Failed to update preferences: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 更新基础货币
  Future<void> updateBaseCurrency(String currency) async {
    final newPreferences = state.preferences.copyWith(baseCurrency: currency);
    await updatePreferences(newPreferences);
  }

  /// 更新刷新间隔
  Future<void> updateRefreshInterval(int minutes) async {
    final newPreferences = state.preferences.copyWith(
      refreshIntervalMinutes: minutes,
    );
    await updatePreferences(newPreferences);
  }

  /// 切换生物识别认证
  Future<void> toggleBiometric(bool enabled) async {
    final newPreferences = state.preferences.copyWith(
      biometricEnabled: enabled,
    );
    await updatePreferences(newPreferences);
  }

  /// 切换市场提醒
  Future<void> toggleMarketAlerts(bool enabled) async {
    final newPreferences = state.preferences.copyWith(
      marketAlertsEnabled: enabled,
    );
    await updatePreferences(newPreferences);
  }

  /// 清除所有数据（DB + SecureStorage + SharedPreferences）
  Future<bool> clearAllData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 清除数据库
      final db = _ref.read(databaseProvider);
      await db.delete(db.holdings).go();
      await db.delete(db.exchangeAccounts).go();
      await db.delete(db.portfolioSnapshots).go();
      await db.delete(db.priceCache).go();

      // 清除密钥
      await _keyManager.clearAll();
      // 重新初始化密钥
      await _keyManager.initialize();

      // 清除偏好设置
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      state = const ProfileState();
      return true;
    } catch (e) {
      debugPrint('Failed to clear all data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 刷新
  Future<void> refreshProfile() async {
    await _loadProfile();
  }
}

/// Profile Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);

/// 用户偏好设置 Provider
final userPreferencesProvider = Provider<UserPreferences>((ref) {
  return ref.watch(profileProvider).preferences;
});

/// 已连接 API 列表 Provider
final connectedApisProvider = Provider<List<ConnectedApi>>((ref) {
  return ref.watch(profileProvider).connectedApis;
});
