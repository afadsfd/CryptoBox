import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 数字扩展
extension NumberExtensions on num {
  /// 格式化为货币字符串
  String toCurrency({
    String symbol = '\$',
    int decimalDigits = 2,
    bool showSign = false,
  }) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    
    String result = formatter.format(this);
    
    if (showSign && this > 0) {
      result = '+$result';
    }
    
    return result;
  }

  /// 格式化为紧凑数字 (如 1.2K, 3.5M)
  String toCompact({int decimalDigits = 1}) {
    return NumberFormat.compactCurrency(
      decimalDigits: decimalDigits,
      symbol: '',
    ).format(this);
  }

  /// 格式化为百分比
  String toPercent({int decimalDigits = 2, bool showSign = true}) {
    final formatter = NumberFormat.percentPattern()
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    
    String result = formatter.format(this / 100);
    
    if (showSign && this > 0) {
      result = '+$result';
    }
    
    return result;
  }

  /// 格式化为固定小数位
  String toFixed(int digits) {
    return toStringAsFixed(digits);
  }
}

/// 字符串扩展
extension StringExtensions on String {
  /// 首字母大写
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// 每个单词首字母大写
  String toTitleCase() {
    return split(' ')
        .map((word) => word.capitalize())
        .join(' ');
  }

  /// 截断字符串并添加省略号
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// 隐藏中间部分 (如 API Key)
  String mask({int visibleStart = 4, int visibleEnd = 4, String mask = '****'}) {
    if (length <= visibleStart + visibleEnd) return this;
    return '${substring(0, visibleStart)}$mask${substring(length - visibleEnd)}';
  }

  /// 是否为有效邮箱
  bool get isValidEmail {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(this);
  }

  /// 是否为有效 URL
  bool get isValidUrl {
    final regex = RegExp(
      r'^(http|https)://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(:[0-9]{1,5})?(/.*)?$',
    );
    return regex.hasMatch(this);
  }
}

/// 日期时间扩展
extension DateTimeExtensions on DateTime {
  /// 格式化为日期字符串
  String toFormattedDate({String pattern = 'yyyy-MM-dd'}) {
    return DateFormat(pattern).format(this);
  }

  /// 格式化为时间字符串
  String toFormattedTime({String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(this);
  }

  /// 格式化为日期时间字符串
  String toFormattedDateTime({String pattern = 'yyyy-MM-dd HH:mm'}) {
    return DateFormat(pattern).format(this);
  }

  /// 相对时间描述
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365}年前';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 是否为今天
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 是否为昨天
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

/// 颜色扩展
extension ColorExtensions on Color {
  /// 获取带透明度的颜色
  Color withOpacityValue(double value) {
    return withOpacity(value.clamp(0.0, 1.0));
  }

  /// 变亮
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// 变暗
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// 转换为十六进制字符串
  String toHex({bool leadingHashSign = true, bool includeAlpha = false}) {
    final alpha = (a * 255).toInt().toRadixString(16).padLeft(2, '0');
    final red = (r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final green = (g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final blue = (b * 255).toInt().toRadixString(16).padLeft(2, '0');

    return '${leadingHashSign ? '#' : ''}'
        '${includeAlpha ? alpha : ''}'
        '$red$green$blue';
  }
}

/// BuildContext 扩展
extension BuildContextExtensions on BuildContext {
  /// 主题数据
  ThemeData get theme => Theme.of(this);

  /// 颜色方案
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 文本主题
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 屏幕尺寸
  Size get screenSize => MediaQuery.of(this).size;

  /// 屏幕宽度
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;

  /// 安全区域边距
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// 是否为深色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 导航器
  NavigatorState get navigator => Navigator.of(this);

  /// 显示 SnackBar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// 隐藏 SnackBar
  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  /// 显示对话框
  Future<T?> showAppDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  /// 显示底部弹窗
  Future<T?> showAppBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      builder: builder,
    );
  }
}

/// Widget 扩展
extension WidgetExtensions on Widget {
  /// 添加内边距
  Widget padding(EdgeInsetsGeometry padding) {
    return Padding(padding: padding, child: this);
  }

  /// 添加对称内边距
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: this,
    );
  }

  /// 添加全向内边距
  Widget paddingAll(double value) {
    return Padding(padding: EdgeInsets.all(value), child: this);
  }

  /// 添加外边距
  Widget margin(EdgeInsetsGeometry margin) {
    return Padding(padding: margin, child: this);
  }

  /// 居中对齐
  Widget get center => Center(child: this);

  /// 展开
  Widget get expanded => Expanded(child: this);

  /// 弹性布局
  Widget flexible({int flex = 1}) {
    return Flexible(flex: flex, child: this);
  }

  /// 点击事件
  Widget onTap(VoidCallback onTap, {HitTestBehavior? behavior}) {
    return GestureDetector(
      onTap: onTap,
      behavior: behavior,
      child: this,
    );
  }

  /// 圆角裁剪
  Widget clipRRect({double radius = 8.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: this,
    );
  }

  /// 圆形裁剪
  Widget get clipOval => ClipOval(child: this);

  /// 可见性控制
  Widget visible(bool visible, {Widget? replacement}) {
    return Visibility(
      visible: visible,
      replacement: replacement ?? const SizedBox.shrink(),
      child: this,
    );
  }

  /// 透明度
  Widget opacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }

  /// Hero 动画
  Widget hero(String tag) {
    return Hero(tag: tag, child: this);
  }
}

/// List 扩展
extension ListExtensions<T> on List<T> {
  /// 安全获取元素
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// 分割列表
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }
}
