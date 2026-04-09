import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get(String key) => (_localizedValues[locale.languageCode] ?? _en)[key] ?? key;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': _en,
    'zh': _zh,
  };

  static const Map<String, String> _en = {
    // General
    'app_name': 'CryptoBox',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'save': 'Save',
    'confirm': 'Confirm',
    'delete': 'Delete',
    'ok': 'OK',
    'connect': 'Connect',
    'disconnect': 'Disconnect',
    'active': 'Active',
    'inactive': 'Inactive',
    'syncing': 'Syncing',
    'synced': 'Synced',
    'pending': 'Pending',
    'search': 'Search',
    'all': 'All',

    // Navigation
    'nav_portfolio': 'Portfolio',
    'nav_connect': 'Connect',
    'nav_settings': 'Settings',

    // Dashboard
    'total_portfolio_value': 'Total Portfolio Value',
    'growth_metrics': 'Growth Metrics',
    'performance_analysis': '30-Day Performance Analysis',
    'top_holdings': 'Top Holdings',
    'no_holdings_title': 'No holdings yet',
    'no_holdings_message': 'Connect an exchange or wallet to start tracking your portfolio.',
    'connect_exchange': 'Connect Exchange',
    'portfolio_updated': 'Portfolio updated',
    'high': 'High',
    'low': 'Low',
    'average': 'Average',
    'connected_nodes': 'Connected Nodes',
    'connected_nodes_desc': 'Your linked exchange accounts',

    // Exchanges
    'exchanges_title': 'Connect Exchanges',
    'exchanges_connected': 'Connected',
    'exchanges_available': 'Available Exchanges',
    'search_exchanges': 'Search exchanges...',
    'exchanges': 'Exchanges',
    'wallets': 'Wallets',
    'no_exchanges_found': 'No exchanges found',
    'no_exchanges_available': 'No exchanges available',
    'try_different_search': 'Try a different search term or clear filters.',
    'pull_to_refresh': 'Pull down to refresh and try again.',
    'clear_search': 'Clear search',
    'disconnect_exchange': 'Disconnect Exchange',
    'disconnect_confirm': 'Are you sure you want to disconnect',
    'read_only_api': 'Read-only API keys only',
    'api_key': 'API Key',
    'api_secret': 'API Secret',
    'passphrase': 'Passphrase',
    'label_optional': 'Label (Optional)',
    'enter_api_key': 'Enter your API key',
    'enter_api_secret': 'Enter your API secret',
    'enter_passphrase': 'Enter your passphrase',
    'label_hint': 'e.g. My Trading Account',
    'exchange_connected': 'Exchange connected successfully!',
    'security_notice': 'Your API keys are encrypted with AES-256 and stored securely. We only request read-only permissions.',

    // Settings
    'settings_title': 'Settings',
    'connected_exchanges': 'Connected Exchanges',
    'no_exchanges_connected': 'No exchanges connected',
    'no_exchanges_hint': 'Go to Connect tab to add your first exchange',
    'preferences': 'Preferences',
    'refresh_interval': 'Refresh Interval',
    'refresh_subtitle': 'Auto-refresh portfolio data',
    'language': 'Language',
    'language_subtitle': 'Choose display language',
    'select_language': 'Select Language',
    'english': 'English',
    'chinese': '中文',
    'clear_all_data': 'Clear All Data',
    'clear_all_data_title': 'Clear All Data',
    'clear_all_data_message': 'This will permanently delete all exchange connections, holdings data, portfolio history, and encryption keys. This action cannot be undone.',
    'clear_all': 'Clear All',
    'data_cleared': 'All data cleared successfully',
    'data_clear_failed': 'Failed to clear data',
    'privacy_first': 'Privacy First',
    'local_tracker': 'Local-only portfolio tracker',
    'select_refresh': 'Select Refresh Interval',
    'minutes': 'minutes',
    'version': 'Version',
    'developer_credit': 'Developed by ZeroAI',
    'contact_developer': 'Contact Developer',
    'contact_email': 'Email',
    'contact_telegram': 'Telegram',

    // Errors
    'page_not_found': 'Page Not Found',
    'go_home': 'Go Home',
  };

  static const Map<String, String> _zh = {
    // General
    'app_name': 'CryptoBox',
    'loading': '加载中...',
    'error': '错误',
    'retry': '重试',
    'cancel': '取消',
    'save': '保存',
    'confirm': '确认',
    'delete': '删除',
    'ok': '确定',
    'connect': '连接',
    'disconnect': '断开连接',
    'active': '活跃',
    'inactive': '未激活',
    'syncing': '同步中',
    'synced': '已同步',
    'pending': '等待中',
    'search': '搜索',
    'all': '全部',

    // Navigation
    'nav_portfolio': '资产',
    'nav_connect': '连接',
    'nav_settings': '设置',

    // Dashboard
    'total_portfolio_value': '投资组合总价值',
    'growth_metrics': '增长指标',
    'performance_analysis': '30天走势分析',
    'top_holdings': '主要持仓',
    'no_holdings_title': '暂无持仓',
    'no_holdings_message': '连接交易所或钱包，开始追踪您的投资组合。',
    'connect_exchange': '连接交易所',
    'portfolio_updated': '数据已更新',
    'high': '最高',
    'low': '最低',
    'average': '平均',
    'connected_nodes': '已连接节点',
    'connected_nodes_desc': '您关联的交易所账户',

    // Exchanges
    'exchanges_title': '连接交易所',
    'exchanges_connected': '已连接',
    'exchanges_available': '可用交易所',
    'search_exchanges': '搜索交易所...',
    'exchanges': '交易所',
    'wallets': '钱包',
    'no_exchanges_found': '未找到交易所',
    'no_exchanges_available': '暂无可用交易所',
    'try_different_search': '尝试其他搜索词或清除筛选条件。',
    'pull_to_refresh': '下拉刷新重试。',
    'clear_search': '清除搜索',
    'disconnect_exchange': '断开交易所',
    'disconnect_confirm': '确定要断开连接吗',
    'read_only_api': '仅需只读 API 密钥',
    'api_key': 'API Key',
    'api_secret': 'API Secret',
    'passphrase': 'Passphrase',
    'label_optional': '标签（可选）',
    'enter_api_key': '请输入 API Key',
    'enter_api_secret': '请输入 API Secret',
    'enter_passphrase': '请输入 Passphrase',
    'label_hint': '例如：我的交易账户',
    'exchange_connected': '交易所连接成功！',
    'security_notice': '您的 API 密钥使用 AES-256 加密并安全存储，我们仅请求只读权限。',

    // Settings
    'settings_title': '设置',
    'connected_exchanges': '已连接的交易所',
    'no_exchanges_connected': '未连接交易所',
    'no_exchanges_hint': '前往"连接"页面添加您的第一个交易所',
    'preferences': '偏好设置',
    'refresh_interval': '刷新间隔',
    'refresh_subtitle': '自动刷新投资组合数据',
    'language': '语言',
    'language_subtitle': '选择显示语言',
    'select_language': '选择语言',
    'english': 'English',
    'chinese': '中文',
    'clear_all_data': '清除所有数据',
    'clear_all_data_title': '清除所有数据',
    'clear_all_data_message': '这将永久删除所有交易所连接、持仓数据、投资组合历史和加密密钥。此操作不可撤销。',
    'clear_all': '全部清除',
    'data_cleared': '所有数据已成功清除',
    'data_clear_failed': '清除数据失败',
    'privacy_first': '隐私优先',
    'local_tracker': '本地化投资组合追踪器',
    'select_refresh': '选择刷新间隔',
    'minutes': '分钟',
    'version': '版本',
    'developer_credit': '由 ZeroAI 开发',
    'contact_developer': '联系开发者',
    'contact_email': '邮箱',
    'contact_telegram': 'Telegram',

    // Errors
    'page_not_found': '页面未找到',
    'go_home': '返回首页',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
