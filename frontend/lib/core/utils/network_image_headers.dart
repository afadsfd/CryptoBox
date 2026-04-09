/// 部分 CDN（含 CoinGecko / CMC）对无 User-Agent 请求会 403，统一加简单 UA。
const kNetworkImageHeaders = {
  'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile) CryptoBox/1.0',
};
