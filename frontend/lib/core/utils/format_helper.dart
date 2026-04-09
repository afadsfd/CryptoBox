/// 格式化辅助工具
class FormatHelper {
  FormatHelper._();

  /// 完整金额：$1,234,567.89（带千分位）
  static String currency(double value, {String symbol = '\$'}) {
    final negative = value < 0;
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${negative ? '-' : ''}$symbol$intPart.${parts[1]}';
  }

  /// 紧凑金额：$1.23K / $1.23M / $1.23B
  static String currencyCompact(double value, {String symbol = '\$'}) {
    final negative = value < 0;
    final abs = value.abs();
    String result;
    if (abs >= 1e9) {
      result = '${(abs / 1e9).toStringAsFixed(2)}B';
    } else if (abs >= 1e6) {
      result = '${(abs / 1e6).toStringAsFixed(2)}M';
    } else if (abs >= 1e3) {
      result = '${(abs / 1e3).toStringAsFixed(2)}K';
    } else {
      result = abs.toStringAsFixed(2);
    }
    return '${negative ? '-' : ''}$symbol$result';
  }

  /// 百分比格式：+12.34% / -5.67%
  static String percent(double value, {int decimals = 2}) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}%';
  }

  /// 相对时间："just now" / "5 min ago" / "2 hours ago" / "Mar 5"
  static String relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[time.month - 1]} ${time.day}';
    }
  }
}
