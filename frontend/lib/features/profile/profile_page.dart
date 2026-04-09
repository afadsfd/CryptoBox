import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'profile_provider.dart';

/// 我的页面 (Profile/Settings) — 本地化版本
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 背景装饰
            SliverToBoxAdapter(
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1,
                    colors: [
                      AppTheme.primaryContainer.withAlpha(26),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // App 标题头部
            SliverToBoxAdapter(
              child: _buildAppHeader(context),
            ),

            // 设置列表
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSecuritySection(context, ref),
                  const SizedBox(height: 24),
                  _buildApiManagementSection(context, ref),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(context, ref),
                  const SizedBox(height: 24),
                  _buildDangerZone(context, ref),
                  const SizedBox(height: 32),
                  _buildVersionInfo(),
                ]),
              ),
            ),

            // 底部留白
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  /// App 标题头部（替代原来的用户资料头部）
  Widget _buildAppHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // App 图标
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.accent,
                  AppTheme.accentCyan,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.background,
                width: 4,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceHighest,
              ),
              child: const Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textOnSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // App 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CryptoFolio',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textOnSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.security,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Local-only portfolio tracker',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentCyan.withAlpha(77),
                    ),
                  ),
                  child: Text(
                    'Privacy First',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建安全设置区域
  Widget _buildSecuritySection(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Security Protocol', Icons.security),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.fingerprint,
                title: 'Biometric Authentication',
                subtitle: 'Use FaceID or TouchID to unlock',
                trailing: Switch(
                  value: preferences.biometricEnabled,
                  onChanged: (value) {
                    ref.read(profileProvider.notifier).toggleBiometric(value);
                  },
                  activeColor: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建 API 管理区域
  Widget _buildApiManagementSection(BuildContext context, WidgetRef ref) {
    final apis = ref.watch(connectedApisProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Connected Exchanges', Icons.terminal),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              if (apis.isEmpty)
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'No exchanges connected',
                  subtitle: 'Go to Connect tab to add your first exchange',
                  iconColor: AppTheme.textSecondary,
                ),
              ...apis.map((api) => _buildApiItem(context, api)),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建 API 列表项
  Widget _buildApiItem(BuildContext context, ConnectedApi api) {
    return _buildSettingItem(
      icon: Icons.terminal,
      title: api.name,
      subtitle: 'Last active: ${api.lastActive}',
      iconBackgroundColor: AppTheme.accent.withAlpha(38),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: (api.isActive ? AppTheme.success : AppTheme.textSecondary)
              .withAlpha(38),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          api.isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: api.isActive ? AppTheme.success : AppTheme.textSecondary,
          ),
        ),
      ),
      onTap: () {},
    );
  }

  /// 构建偏好设置区域
  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Preferences', Icons.tune),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              // 基础货币
              _buildSettingItem(
                icon: Icons.payments,
                title: 'Base Currency',
                subtitle: _getCurrencyFullName(preferences.baseCurrency),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preferences.baseCurrency,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textOnSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.expand_more,
                      color: AppTheme.textOnSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showCurrencySelector(context, ref),
              ),
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              // 刷新间隔
              _buildSettingItem(
                icon: Icons.sync,
                title: 'Refresh Interval',
                subtitle: 'Auto-refresh portfolio data',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${preferences.refreshIntervalMinutes} min',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textOnSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.expand_more,
                      color: AppTheme.textOnSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _showRefreshIntervalSelector(context, ref),
              ),
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              // 市场提醒
              _buildSettingItem(
                icon: Icons.notifications_active,
                title: 'Market Alerts',
                subtitle: 'Push notifications for high volatility',
                trailing: Switch(
                  value: preferences.marketAlertsEnabled,
                  onChanged: (value) {
                    ref.read(profileProvider.notifier).toggleMarketAlerts(value);
                  },
                  activeColor: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建危险操作区域 — 清除所有数据
  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.error.withAlpha(51),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showClearAllDataDialog(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_forever,
                  size: 18,
                  color: AppTheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Clear All Data',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建版本信息
  Widget _buildVersionInfo() {
    return Center(
      child: Text(
        'Version v1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  /// 构建区块标题
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textOnSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textOnSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    Color? iconBackgroundColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppTheme.textOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  /// 获取货币全称
  String _getCurrencyFullName(String currency) {
    final names = {
      'USD': 'United States Dollar (USD)',
      'EUR': 'Euro (EUR)',
      'GBP': 'British Pound (GBP)',
      'JPY': 'Japanese Yen (JPY)',
      'CNY': 'Chinese Yuan (CNY)',
    };
    return names[currency] ?? currency;
  }

  /// 显示货币选择器
  void _showCurrencySelector(BuildContext context, WidgetRef ref) {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY'];
    final preferences = ref.read(userPreferencesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Base Currency',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textOnSurface,
                ),
              ),
            ),
            ...currencies.map((currency) => ListTile(
                  leading: Text(
                    _getCurrencyFlag(currency),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    _getCurrencyFullName(currency),
                    style: TextStyle(color: AppTheme.textOnSurface),
                  ),
                  trailing: preferences.baseCurrency == currency
                      ? const Icon(Icons.check, color: AppTheme.accent)
                      : null,
                  onTap: () {
                    ref
                        .read(profileProvider.notifier)
                        .updateBaseCurrency(currency);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 获取货币旗帜
  String _getCurrencyFlag(String currency) {
    final flags = {
      'USD': '🇺🇸',
      'EUR': '🇪🇺',
      'GBP': '🇬🇧',
      'JPY': '🇯🇵',
      'CNY': '🇨🇳',
    };
    return flags[currency] ?? '💱';
  }

  /// 显示刷新间隔选择器
  void _showRefreshIntervalSelector(BuildContext context, WidgetRef ref) {
    final intervals = [5, 15, 30, 60];
    final preferences = ref.read(userPreferencesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Refresh Interval',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textOnSurface,
                ),
              ),
            ),
            ...intervals.map((interval) => ListTile(
                  leading: Icon(
                    Icons.timer,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    '$interval minutes',
                    style: TextStyle(color: AppTheme.textOnSurface),
                  ),
                  trailing: preferences.refreshIntervalMinutes == interval
                      ? const Icon(Icons.check, color: AppTheme.accent)
                      : null,
                  onTap: () {
                    ref
                        .read(profileProvider.notifier)
                        .updateRefreshInterval(interval);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 显示清除所有数据确认对话框
  void _showClearAllDataDialog(BuildContext outerContext, WidgetRef ref) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.error),
            const SizedBox(width: 8),
            Text(
              'Clear All Data',
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all exchange connections, holdings data, portfolio history, and encryption keys. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textOnSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success =
                  await ref.read(profileProvider.notifier).clearAllData();
              if (outerContext.mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'All data cleared successfully'
                          : 'Failed to clear data',
                    ),
                    backgroundColor: success ? AppTheme.success : AppTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
