import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/l10n/app_localizations.dart';
import 'core/security/key_manager.dart';
import 'core/security/security_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置系统 UI 样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 设置首选屏幕方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 初始化 KeyManager（必须在 runApp 之前完成）
  final keyManager = KeyManager();
  await keyManager.initialize();

  runApp(
    ProviderScope(
      overrides: [
        keyManagerProvider.overrideWithValue(keyManager),
      ],
      child: const CryptoFolioApp(),
    ),
  );
}

/// CryptoFolio 应用
class CryptoFolioApp extends ConsumerWidget {
  const CryptoFolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'CryptoFolio',
      debugShowCheckedModeBanner: false,

      // 主题配置
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // 路由配置
      routerConfig: ref.watch(routerProvider),
      
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      
      // 构建器配置
      builder: (context, child) {
        // 可以在这里添加全局的 UI 组件，如 Toast、Loading 等
        return MediaQuery(
          // 设置文字缩放因子为 1.0，防止系统字体大小影响布局
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}
