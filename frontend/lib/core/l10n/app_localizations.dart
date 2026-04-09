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
    'app_name': 'CryptoFolio',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'save': 'Save',
    'confirm': 'Confirm',
    'delete': 'Delete',
    'ok': 'OK',

    // Navigation
    'nav_portfolio': 'Portfolio',
    'nav_connect': 'Connect',
    'nav_markets': 'Markets',
    'nav_settings': 'Settings',

    // Auth
    'login_title': 'Welcome Back',
    'login_subtitle': 'Sign in to continue...',
    'login_email': 'Email',
    'login_password': 'Password',
    'login_button': 'Sign In',
    'login_forgot_password': 'Forgot Password?',
    'login_no_account': "Don't have an account? ",
    'login_sign_up': 'Sign Up',
    'login_with_google': 'Continue with Google',
    'login_with_apple': 'Continue with Apple',
    'register_title': 'Create Account',
    'register_subtitle': 'Start tracking your portfolio',
    'register_name': 'Full Name',
    'register_email': 'Email',
    'register_password': 'Password',
    'register_confirm_password': 'Confirm Password',
    'register_button': 'Create Account',
    'register_has_account': 'Already have an account? ',
    'register_sign_in': 'Sign In',

    // Router
    'page_not_found': 'Page Not Found',
    'go_home': 'Go Home',
    'markets_title': 'Markets',
    'markets_page': 'Markets',
    'markets_coming_soon': 'Coming Soon',

    // Dashboard
    'dashboard_title': 'Portfolio',
    'total_portfolio_value': 'Total Portfolio Value',
    'growth_metrics': 'Growth Metrics',
    'top_holdings': 'Top Holdings',
    'connected_nodes': 'Connected Nodes',

    // Exchanges
    'exchanges_title': 'Connect Exchanges',
    'exchanges_connected': 'Connected',
    'exchanges_available': 'Available',
    'exchanges_add_api': 'Add API',
    'exchanges_disconnect': 'Disconnect',

    // Profile
    'profile_title': 'Settings',
    'profile_edit': 'Edit Profile',
    'profile_preferences': 'Preferences',
    'profile_security': 'Security',
    'profile_logout': 'Sign Out',
    'profile_logout_all': 'Sign Out All Devices',

    // Onboarding
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_get_started': 'Get Started',
    'onboarding_title_1': 'Track Your Portfolio',
    'onboarding_desc_1': 'Monitor all your crypto assets across multiple exchanges in one place.',
    'onboarding_title_2': 'Connect Exchanges',
    'onboarding_desc_2': 'Securely connect your exchange accounts using read-only API keys.',
    'onboarding_title_3': 'Real-time Analytics',
    'onboarding_desc_3': 'Get detailed insights, charts, and performance metrics for your portfolio.',
  };

  static const Map<String, String> _zh = {
    // General
    'app_name': 'CryptoFolio',
    'loading': '加载中...',
    'error': '错误',
    'retry': '重试',
    'cancel': '取消',
    'save': '保存',
    'confirm': '确认',
    'delete': '删除',
    'ok': '确定',

    // Navigation
    'nav_portfolio': '资产',
    'nav_connect': '连接',
    'nav_markets': '市场',
    'nav_settings': '设置',

    // Auth
    'login_title': '欢迎回来',
    'login_subtitle': '登录以继续...',
    'login_email': '邮箱',
    'login_password': '密码',
    'login_button': '登录',
    'login_forgot_password': '忘记密码?',
    'login_no_account': '还没有账号？',
    'login_sign_up': '注册',
    'login_with_google': '使用 Google 继续',
    'login_with_apple': '使用 Apple 继续',
    'register_title': '创建账号',
    'register_subtitle': '开始追踪您的投资组合',
    'register_name': '姓名',
    'register_email': '邮箱',
    'register_password': '密码',
    'register_confirm_password': '确认密码',
    'register_button': '创建账号',
    'register_has_account': '已有账号？',
    'register_sign_in': '登录',

    // Router
    'page_not_found': '页面未找到',
    'go_home': '返回首页',
    'markets_title': '市场',
    'markets_page': '市场',
    'markets_coming_soon': '即将推出',

    // Dashboard
    'dashboard_title': '资产总览',
    'total_portfolio_value': '投资组合总价值',
    'growth_metrics': '增长指标',
    'top_holdings': '主要持仓',
    'connected_nodes': '已连接节点',

    // Exchanges
    'exchanges_title': '连接交易所',
    'exchanges_connected': '已连接',
    'exchanges_available': '可用',
    'exchanges_add_api': '添加 API',
    'exchanges_disconnect': '断开连接',

    // Profile
    'profile_title': '设置',
    'profile_edit': '编辑资料',
    'profile_preferences': '偏好设置',
    'profile_security': '安全',
    'profile_logout': '退出登录',
    'profile_logout_all': '退出所有设备',

    // Onboarding
    'onboarding_skip': '跳过',
    'onboarding_next': '下一步',
    'onboarding_get_started': '开始使用',
    'onboarding_title_1': '追踪您的投资组合',
    'onboarding_desc_1': '在一个地方监控您在多个交易所的所有加密资产。',
    'onboarding_title_2': '连接交易所',
    'onboarding_desc_2': '使用只读 API 密钥安全连接您的交易所账户。',
    'onboarding_title_3': '实时分析',
    'onboarding_desc_3': '获取投资组合的详细洞察、图表和绩效指标。',
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
