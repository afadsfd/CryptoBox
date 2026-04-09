import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 骨架屏基础组件 - shimmer 动画
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                final dx = bounds.width * (_controller.value * 2 - 1);
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.surfaceHigh,
                    AppTheme.surfaceHighest,
                    AppTheme.surfaceHigh,
                  ],
                  stops: const [0.35, 0.5, 0.65],
                  transform: _SlideTransform(dx),
                ).createShader(bounds);
              },
              child: Container(color: AppTheme.surfaceHigh),
            );
          },
        ),
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  final double dx;
  const _SlideTransform(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(dx);
  }
}

/// Dashboard 骨架屏
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: 140, height: 12),
            const SizedBox(height: 12),
            const Skeleton(width: 220, height: 38),
            const SizedBox(height: 12),
            const Skeleton(width: 160, height: 20),
            const SizedBox(height: 24),
            // 图表卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface.withAlpha(102),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border.withAlpha(102)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 150, height: 18),
                  const SizedBox(height: 8),
                  const Skeleton(width: 200, height: 12),
                  const SizedBox(height: 20),
                  const Skeleton(height: 180, borderRadius: 12),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      3,
                      (_) => const Skeleton(width: 60, height: 30),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Skeleton(width: 120, height: 20),
            const SizedBox(height: 12),
            // 持仓卡片骨架
            ...List.generate(3, (i) => const _HoldingSkeletonRow()),
          ],
        ),
      ),
    );
  }
}

class _HoldingSkeletonRow extends StatelessWidget {
  const _HoldingSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withAlpha(102),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withAlpha(102)),
      ),
      child: Row(
        children: [
          const Skeleton(width: 36, height: 36, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 100, height: 14),
                SizedBox(height: 6),
                Skeleton(width: 60, height: 10),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Skeleton(width: 70, height: 14),
              SizedBox(height: 6),
              Skeleton(width: 40, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// 交易所 Grid 骨架屏
class ExchangesSkeleton extends StatelessWidget {
  const ExchangesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(102),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withAlpha(102)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 44, height: 44, borderRadius: 22),
                SizedBox(height: 12),
                Skeleton(width: 80, height: 14),
                SizedBox(height: 6),
                Skeleton(width: 120, height: 10),
                SizedBox(height: 6),
                Skeleton(width: 100, height: 10),
                Spacer(),
                Skeleton(height: 32, borderRadius: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
