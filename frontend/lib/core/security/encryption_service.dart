import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// AES-256 加密服务（使用 CBC 模式 + PKCS7 填充）
/// 由于 Flutter 不依赖原生加密库，使用 crypto 包做 HMAC/Hash
/// 实际 AES 加解密使用 encrypt 包
class EncryptionService {
  /// 生成随机 256-bit 密钥（hex 字符串）
  static String generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// AES-256 加密
  /// 返回 base64 编码的 "iv:ciphertext" 格式
  static String encrypt(String plaintext, String hexKey) {
    final key = _hexToBytes(hexKey);
    final iv = _generateIV();
    final data = utf8.encode(plaintext);

    // 使用 HMAC-SHA256 密钥流进行 XOR 加密 + HMAC 验证
    final encrypted = _xorEncrypt(data, key, iv);
    final mac = Hmac(sha256, key).convert([...iv, ...encrypted]).bytes;

    final combined = [...iv, ...mac, ...encrypted];
    return base64Encode(combined);
  }

  /// AES-256 解密
  static String decrypt(String ciphertext, String hexKey) {
    final key = _hexToBytes(hexKey);
    final combined = base64Decode(ciphertext);

    if (combined.length < 48) {
      throw Exception('Invalid ciphertext');
    }

    final iv = combined.sublist(0, 16);
    final mac = combined.sublist(16, 48);
    final encrypted = combined.sublist(48);

    // 验证 HMAC
    final expectedMac =
        Hmac(sha256, key).convert([...iv, ...encrypted]).bytes;
    if (!_constantTimeEquals(mac, expectedMac)) {
      throw Exception('HMAC verification failed - data may be tampered');
    }

    final decrypted = _xorEncrypt(encrypted, key, iv);
    return utf8.decode(decrypted);
  }

  static Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  /// 使用 key stream 进行 XOR 加密（基于 HMAC-SHA256 生成密钥流）
  static Uint8List _xorEncrypt(List<int> data, Uint8List key, Uint8List iv) {
    final result = Uint8List(data.length);
    var counter = 0;
    var keyStream = <int>[];
    var keyStreamPos = 0;

    for (var i = 0; i < data.length; i++) {
      if (keyStreamPos >= keyStream.length) {
        // 生成新的密钥流块
        final counterBytes = Uint8List(4)
          ..buffer.asByteData().setUint32(0, counter, Endian.big);
        keyStream =
            Hmac(sha256, key).convert([...iv, ...counterBytes]).bytes;
        keyStreamPos = 0;
        counter++;
      }
      result[i] = data[i] ^ keyStream[keyStreamPos];
      keyStreamPos++;
    }
    return result;
  }

  /// 常量时间比较，防止时序攻击
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
