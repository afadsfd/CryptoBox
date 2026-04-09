import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import 'profile_provider.dart';

String _brandMonogram(AppLocalizations l10n) {
  final n = l10n.get('app_name');
  if (n.isEmpty) return '?';
  return n.substring(0, 1).toUpperCase();
}

Future<PackageInfo>? _cachedPackageInfo;
Future<PackageInfo> _loadPackageInfoOnce() =>
    _cachedPackageInfo ??= PackageInfo.fromPlatform();

Future<void> _launchExternalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('无法打开链接')),
      );
    }
  }
}

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
                  _buildApiManagementSection(context, ref),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(context, ref),
                  const SizedBox(height: 24),
                  _buildDeveloperSection(context),
                  const SizedBox(height: 24),
                  _buildDangerZone(context, ref),
                  const SizedBox(height: 32),
                  _buildVersionInfo(context),
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
    final l10n = AppLocalizations.of(context);
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
              child: Center(
                child: Text(
                  _brandMonogram(l10n),
                  style: const TextStyle(
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
                  l10n.get('app_name'),
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
                      l10n.get('local_tracker'),
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
                    l10n.get('privacy_first'),
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

  /// 构建 API 管理区域
  Widget _buildApiManagementSection(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final apis = ref.watch(connectedApisProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.get('connected_exchanges'), Icons.terminal),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              if (apis.isEmpty)
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: l10n.get('no_exchanges_connected'),
                  subtitle: l10n.get('no_exchanges_hint'),
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
    final l10n = AppLocalizations.of(context);
    final preferences = ref.watch(userPreferencesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.get('preferences'), Icons.tune),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              // 刷新间隔
              _buildSettingItem(
                icon: Icons.sync,
                title: l10n.get('refresh_interval'),
                subtitle: l10n.get('refresh_subtitle'),
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
              // 语言选择
              _buildSettingItem(
                icon: Icons.language,
                title: l10n.get('language'),
                subtitle: l10n.get('language_subtitle'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preferences.languageCode == 'zh' ? '中文' : 'English',
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
                onTap: () => _showLanguageSelector(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建危险操作区域 — 清除所有数据
  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

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
                  l10n.get('clear_all_data'),
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

  /// 关于 / 开发者
  Widget _buildDeveloperSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const email = 'lz3862680@gmail.com';
    const tgLabel = '@sky87531';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.get('contact_developer'), Icons.support_agent),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  l10n.get('developer_credit'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOnSurfaceVariant,
                  ),
                ),
              ),
              const Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: AppTheme.border,
              ),
              _buildSettingItem(
                icon: Icons.mail_outline,
                title: l10n.get('contact_email'),
                subtitle: email,
                iconColor: AppTheme.accentCyan,
                onTap: () => _launchExternalUrl(context, 'mailto:$email'),
              ),
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              _buildSettingItem(
                icon: Icons.chat_bubble_outline,
                title: l10n.get('contact_telegram'),
                subtitle: tgLabel,
                iconColor: AppTheme.accent,
                onTap: () =>
                    _launchExternalUrl(context, 'https://t.me/sky87531'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建版本信息（与 pubspec 同步）
  Widget _buildVersionInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<PackageInfo>(
      future: _loadPackageInfoOnce(),
      builder: (context, snap) {
        final ver = snap.data?.version ?? '1.1.0';
        return Center(
          child: Text(
            '${l10n.get('version')} v$ver',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      },
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

  /// 显示刷新间隔选择器
  void _showRefreshIntervalSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                l10n.get('select_refresh'),
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
                    '$interval ${l10n.get('minutes')}',
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
  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                l10n.get('select_language'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textOnSurface,
                ),
              ),
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text('English', style: TextStyle(color: AppTheme.textOnSurface)),
              trailing: preferences.languageCode == 'en'
                  ? const Icon(Icons.check, color: AppTheme.accent)
                  : null,
              onTap: () {
                ref.read(profileProvider.notifier).updateLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇨🇳', style: TextStyle(fontSize: 24)),
              title: Text('中文', style: TextStyle(color: AppTheme.textOnSurface)),
              trailing: preferences.languageCode == 'zh'
                  ? const Icon(Icons.check, color: AppTheme.accent)
                  : null,
              onTap: () {
                ref.read(profileProvider.notifier).updateLanguage('zh');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showClearAllDataDialog(BuildContext outerContext, WidgetRef ref) {
    final l10n = AppLocalizations.of(outerContext);

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.error),
            const SizedBox(width: 8),
            Text(
              l10n.get('clear_all_data_title'),
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textOnSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.get('clear_all_data_message'),
          style: TextStyle(color: AppTheme.textOnSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.get('cancel'),
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
                          ? l10n.get('data_cleared')
                          : l10n.get('data_clear_failed'),
                    ),
                    backgroundColor: success ? AppTheme.success : AppTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text(l10n.get('clear_all')),
          ),
        ],
      ),
    );
  }
}
