/// API 常量配置
class ApiConstants {
  ApiConstants._();

  // 基础 URL (可通过环境变量覆盖)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // 超时配置
  static const int connectTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000; // 30秒
  static const int sendTimeout = 30000; // 30秒

  // API 端点
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String logoutAll = '/auth/logout-all';

  // 用户相关
  static const String userProfile = '/user/profile';
  static const String userPreferences = '/user/preferences';
  static const String userSecurity = '/user/security';

  // 交易所相关
  static const String exchanges = '/exchanges';
  static const String exchangeDetail = '/exchanges/{id}';
  static const String exchangeConnect = '/exchanges/connect';
  static const String exchangesConnected = '/exchanges/connected';

  // 资产相关
  static const String portfolio = '/portfolio';
  static const String portfolioSummary = '/portfolio/summary';
  static const String portfolioHistory = '/portfolio/history';
  static const String portfolioSources = '/portfolio/sources';
  static const String assets = '/portfolio/holdings';
  static const String assetDetail = '/assets/{id}';

  // 市场数据
  static const String marketData = '/market/data';
  static const String marketPrices = '/market/prices';

  // API Keys
  static const String apiKeys = '/user/apis';

  // 头部字段
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String bearerPrefix = 'Bearer';

  // 内容类型
  static const String applicationJson = 'application/json';
}
