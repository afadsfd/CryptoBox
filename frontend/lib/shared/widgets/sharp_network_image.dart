import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/network_image_headers.dart';
import '../../core/utils/raster_image_url.dart';

/// 网络图标：高分辨率 URL + 按 DPR 解码 + 更高 filterQuality，减轻发糊。
class SharpNetworkImage extends StatelessWidget {
  const SharpNetworkImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  static int _cacheExtentPx(BuildContext context, double w, double h) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = math.max(w, h);
    return (side * dpr).ceil().clamp(96, 512);
  }

  @override
  Widget build(BuildContext context) {
    final url = upgradeRasterImageUrl(imageUrl);
    final px = _cacheExtentPx(context, width, height);

    Widget child = CachedNetworkImage(
      imageUrl: url,
      cacheKey: url,
      httpHeaders: kNetworkImageHeaders,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      memCacheWidth: px,
      memCacheHeight: px,
      maxWidthDiskCache: 512,
      maxHeightDiskCache: 512,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }
}
