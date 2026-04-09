/// 将常见 CDN 的缩略图 URL 换成更高分辨率版本（减少高 DPI 下放大发糊）。
String upgradeRasterImageUrl(String url) {
  final u = url.trim();
  if (u.isEmpty) return u;

  if (u.contains('assets.coingecko.com')) {
    if (u.contains('/small/')) {
      return u.replaceFirst('/small/', '/large/');
    }
    if (u.contains('/thumb/')) {
      return u.replaceFirst('/thumb/', '/large/');
    }
  }

  if (u.contains('coinmarketcap.com/static/img/exchanges/')) {
    return u
        .replaceAll('/64x64/', '/200x200/')
        .replaceAll('/128x128/', '/200x200/');
  }

  return u;
}
