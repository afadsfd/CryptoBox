import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/router.dart';

/// 主布局 Scaffold
/// 
/// 包含底部 Tab 导航，使用 Material Icons
/// 深色主题样式，选中项为蓝色高亮
class MainScaffold extends StatelessWidget {
  /// 导航 Shell
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background.withAlpha(242),
        border: const Border(
          top: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final navItem in NavShellIndex.values)
                _buildNavItem(navItem),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建导航项
  Widget _buildNavItem(NavShellIndex navItem) {
    final isSelected = navigationShell.currentIndex == navItem.navIndex;

    return GestureDetector(
      onTap: () => _onTap(navItem.navIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentCyan.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                isSelected ? navItem.activeIcon : navItem.icon,
                color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              navItem.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 导航点击处理
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// 带侧边栏的桌面布局 (响应式)
class DesktopMainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DesktopMainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边导航栏
          Container(
            width: 80,
            color: AppTheme.background.withAlpha(242),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.accentCyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryContainer.withAlpha(77),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: AppTheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 48),
                // 导航项
                Expanded(
                  child: Column(
                    children: [
                      for (final navItem in NavShellIndex.values)
                        _buildDesktopNavItem(navItem),
                    ],
                  ),
                ),
                // 底部用户头像
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryContainer,
                      border: Border.all(
                        color: AppTheme.border,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 22,
                        color: AppTheme.textOnSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // 主内容区
          Expanded(
            child: navigationShell,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem(NavShellIndex navItem) {
    final isSelected = navigationShell.currentIndex == navItem.navIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: navItem.label,
        preferBelow: false,
        child: GestureDetector(
          onTap: () => _onTap(navItem.navIndex),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
              ? AppTheme.accentCyan.withAlpha(26)
              : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSelected ? navItem.activeIcon : navItem.icon,
              color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// 响应式主布局
/// 
/// 根据屏幕宽度自动切换移动端和桌面端布局
class ResponsiveMainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ResponsiveMainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 屏幕宽度大于 768px 使用桌面布局
        if (constraints.maxWidth > 768) {
          return DesktopMainScaffold(
            navigationShell: navigationShell,
          );
        }
        // 否则使用移动端布局
        return MainScaffold(
          navigationShell: navigationShell,
        );
      },
    );
  }
}
