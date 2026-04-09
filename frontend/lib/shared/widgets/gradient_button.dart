import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// 渐变按钮组件
/// 
/// 蓝色到青色渐变 (accent -> accentCyan)
/// 圆角、按压缩放动画、发光阴影效果
class GradientButton extends StatefulWidget {
  /// 按钮文本
  final String? text;
  
  /// 子组件 (优先于 text)
  final Widget? child;
  
  /// 点击回调
  final VoidCallback? onPressed;
  
  /// 渐变颜色
  final List<Color>? gradientColors;
  
  /// 渐变方向
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 内边距
  final EdgeInsetsGeometry padding;
  
  /// 高度
  final double? height;
  
  /// 宽度
  final double? width;
  
  /// 是否显示发光效果
  final bool enableGlow;
  
  /// 发光强度
  final double glowIntensity;
  
  /// 发光颜色
  final Color? glowColor;
  
  /// 文本样式
  final TextStyle? textStyle;
  
  /// 图标
  final Widget? icon;
  
  /// 图标位置
  final bool iconAfterText;
  
  /// 禁用时的背景色
  final Color? disabledColor;

  const GradientButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.gradientColors,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 16,
    ),
    this.height,
    this.width,
    this.enableGlow = true,
    this.glowIntensity = 0.3,
    this.glowColor,
    this.textStyle,
    this.icon,
    this.iconAfterText = true,
    this.disabledColor,
  }) : assert(
         text != null || child != null,
         'Either text or child must be provided',
       );

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? [
      AppTheme.accent,
      AppTheme.accentCyan,
    ];

    final glow = widget.glowColor ?? AppTheme.primaryContainer;
    final isDisabled = widget.onPressed == null;

    Widget buttonContent = widget.child ?? _buildDefaultContent();

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: widget.height,
            width: widget.width,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: isDisabled
                  ? null
                  : LinearGradient(
                      begin: widget.begin,
                      end: widget.end,
                      colors: colors,
                    ),
              color: isDisabled
                  ? (widget.disabledColor ?? AppTheme.surfaceHighest)
                  : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: isDisabled || !widget.enableGlow
                  ? null
                  : [
                      BoxShadow(
                        color: glow.withAlpha(((_isPressed
                                ? widget.glowIntensity * 0.5
                                : widget.glowIntensity) * 255).round()),
                        blurRadius: _isPressed ? 15 : 20,
                        spreadRadius: _isPressed ? 0 : 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: glow.withAlpha(((_isPressed
                                ? widget.glowIntensity * 0.25
                                : widget.glowIntensity * 0.5) * 255).round()),
                        blurRadius: _isPressed ? 25 : 40,
                        spreadRadius: -5,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(child: buttonContent),
          ),
        );
      },
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: button,
    );
  }

  Widget _buildDefaultContent() {
    final style = widget.textStyle ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: widget.onPressed != null
              ? AppTheme.onPrimaryContainer
              : AppTheme.textSecondary,
        );

    final textWidget = Text(
      widget.text!,
      style: style,
    );

    if (widget.icon == null) {
      return textWidget;
    }

    final children = widget.iconAfterText
        ? [
            textWidget,
            const SizedBox(width: 8),
            widget.icon!,
          ]
        : [
            widget.icon!,
            const SizedBox(width: 8),
            textWidget,
          ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// 带边框的渐变按钮
class OutlinedGradientButton extends StatelessWidget {
  /// 按钮文本
  final String? text;
  
  /// 子组件
  final Widget? child;
  
  /// 点击回调
  final VoidCallback? onPressed;
  
  /// 渐变颜色 (用于边框)
  final List<Color>? gradientColors;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 内边距
  final EdgeInsetsGeometry padding;
  
  /// 高度
  final double? height;
  
  /// 宽度
  final double? width;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 背景色
  final Color? backgroundColor;
  
  /// 文本样式
  final TextStyle? textStyle;

  const OutlinedGradientButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.gradientColors,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 16,
    ),
    this.height,
    this.width,
    this.borderWidth = 1.5,
    this.backgroundColor,
    this.textStyle,
  }) : assert(
         text != null || child != null,
         'Either text or child must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [
      AppTheme.accent,
      AppTheme.accentCyan,
    ];

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppTheme.background,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              splashColor: colors.first.withAlpha(26),
              highlightColor: colors.first.withAlpha(13),
              child: Container(
                padding: padding,
                child: Center(
                  child: child ??
                      Text(
                        text!,
                        style: textStyle ??
                            TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onPressed != null
                                  ? colors.first
                                  : AppTheme.textSecondary,
                            ),
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 小型渐变按钮
class SmallGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SmallGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      borderRadius: 10,
      icon: icon != null
          ? Icon(
              icon,
              size: 16,
              color: AppTheme.onPrimaryContainer,
            )
          : null,
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      enableGlow: false,
    );
  }
}
