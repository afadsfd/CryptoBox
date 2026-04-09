import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 毛玻璃效果卡片组件
/// 
/// 使用 BackdropFilter + ImageFilter.blur 实现毛玻璃效果
/// 半透明背景、1px 边框、16px 圆角
class GlassCard extends StatelessWidget {
  /// 子组件
  final Widget child;
  
  /// 内边距
  final EdgeInsetsGeometry? padding;
  
  /// 外边距
  final EdgeInsetsGeometry? margin;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 背景透明度 (0.0 - 1.0)
  final double backgroundOpacity;
  
  /// 模糊强度
  final double blurSigma;
  
  /// 边框颜色
  final Color? borderColor;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 背景颜色 (默认使用 surface)
  final Color? backgroundColor;
  
  /// 阴影
  final List<BoxShadow>? boxShadow;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 长按回调
  final VoidCallback? onLongPress;
  
  /// 高度
  final double? height;
  
  /// 宽度
  final double? width;
  
  /// 对齐方式
  final AlignmentGeometry? alignment;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.backgroundOpacity = 0.6,
    this.blurSigma = 40.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor,
    this.boxShadow,
    this.onTap,
    this.onLongPress,
    this.height,
    this.width,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          height: height,
          width: width,
          alignment: alignment,
          padding: padding,
          decoration: BoxDecoration(
            color: (backgroundColor ?? AppTheme.surface)
                .withAlpha((backgroundOpacity * 255).round()),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppTheme.border,
              width: borderWidth,
            ),
            boxShadow: boxShadow ?? _defaultShadow,
          ),
          child: child,
        ),
      ),
    );

    // 添加点击效果
    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppTheme.primaryContainer.withAlpha(26),
          highlightColor: AppTheme.primaryContainer.withAlpha(13),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }

  /// 默认阴影
  List<BoxShadow> get _defaultShadow => [
    BoxShadow(
      color: AppTheme.primaryContainer.withAlpha(15),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];
}

/// 渐变毛玻璃卡片
class GradientGlassCard extends StatelessWidget {
  /// 子组件
  final Widget child;
  
  /// 内边距
  final EdgeInsetsGeometry? padding;
  
  /// 外边距
  final EdgeInsetsGeometry? margin;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 渐变颜色
  final List<Color>? gradientColors;
  
  /// 渐变方向
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  
  /// 模糊强度
  final double blurSigma;
  
  /// 边框颜色
  final Color? borderColor;
  
  /// 点击回调
  final VoidCallback? onTap;

  const GradientGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.gradientColors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.blurSigma = 40.0,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [
      AppTheme.surfaceHighest.withAlpha(102),
      AppTheme.surface.withAlpha(51),
    ];

    return GlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      borderColor: borderColor,
      onTap: onTap,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

/// 带发光效果的毛玻璃卡片
class GlowGlassCard extends StatelessWidget {
  /// 子组件
  final Widget child;
  
  /// 内边距
  final EdgeInsetsGeometry? padding;
  
  /// 外边距
  final EdgeInsetsGeometry? margin;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 发光颜色
  final Color? glowColor;
  
  /// 发光强度
  final double glowIntensity;
  
  /// 模糊强度
  final double blurSigma;
  
  /// 点击回调
  final VoidCallback? onTap;

  const GlowGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.glowColor,
    this.glowIntensity = 0.15,
    this.blurSigma = 40.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppTheme.primaryContainer;

    return GlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      borderColor: glow.withAlpha(77),
      onTap: onTap,
      boxShadow: [
        BoxShadow(
          color: glow.withAlpha((glowIntensity * 255).round()),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: glow.withAlpha((glowIntensity * 0.5 * 255).round()),
          blurRadius: 40,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ],
      child: child,
    );
  }
}
