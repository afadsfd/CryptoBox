import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_page.dart';
import '../features/exchanges/exchanges_page.dart';
import '../features/exchanges/add_api_page.dart';
import '../features/profile/profile_page.dart';
import '../core/l10n/app_localizations.dart';
import '../shared/widgets/main_scaffold.dart';

/// GoRouter Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: _routes,
    errorBuilder: _errorBuilder,
  );
});

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  // 主页面 (带底部导航)
  static const String home = '/';
  static const String connect = '/connect';
  static const String profile = '/profile';

  // 交易所相关
  static const String addApi = '/connect/:exchangeId';

  /// 构建添加 API 页面路径
  static String addApiPath(String exchangeId) => '/connect/$exchangeId';
}

/// 导航 Shell 索引
enum NavShellIndex {
  portfolio(0, 'Portfolio', Icons.pie_chart_outline, Icons.pie_chart),
  connect(1, 'Connect', Icons.link_outlined, Icons.link),
  settings(2, 'Settings', Icons.settings_outlined, Icons.settings);

  final int navIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavShellIndex(
    this.navIndex,
    this.label,
    this.icon,
    this.activeIcon,
  );
}

/// 滑动转场动画 (from right)
CustomTransitionPage<T> _slideTransitionPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// 路由列表
final _routes = <RouteBase>[
    // Shell 路由 (带底部导航)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(
          navigationShell: navigationShell,
        );
      },
      branches: [
        // Portfolio (首页)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),

        // Connect (交易所连接)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.connect,
              builder: (context, state) => const ExchangesPage(),
              routes: [
                // 添加 API 子页面
                GoRoute(
                  path: ':exchangeId',
                  pageBuilder: (context, state) {
                    final exchangeId = state.pathParameters['exchangeId']!;
                    return _slideTransitionPage(
                      key: state.pageKey,
                      child: AddApiPage(exchangeId: exchangeId),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Settings (设置/我的)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
];

/// 错误页面构建器
Widget _errorBuilder(BuildContext context, GoRouterState state) {
  final l10n = AppLocalizations.of(context);
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.get('page_not_found'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.toString() ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(l10n.get('go_home')),
          ),
        ],
      ),
    ),
  );
}

/// 路由导航扩展
extension GoRouterExtension on BuildContext {
  /// 跳转到首页
  void goHome() => go(AppRoutes.home);

  /// 跳转到交易所连接页
  void goConnect() => go(AppRoutes.connect);

  /// 跳转到添加 API 页
  void goAddApi(String exchangeId) => go(AppRoutes.addApiPath(exchangeId));

  /// 跳转到个人设置页
  void goProfile() => go(AppRoutes.profile);

  /// 带参数推送页面
  void pushAddApi(String exchangeId) => push(AppRoutes.addApiPath(exchangeId));
}
