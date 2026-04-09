import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';

/// 密钥管理器
/// - 管理主密钥（存储在系统安全存储中：iOS Keychain / Android Keystore）
/// - 提供 API Key 的加密和解密功能
class KeyManager {
  static const _masterKeyStorageKey = 'cryptofolio_master_key';
  final FlutterSecureStorage _secureStorage;
  String? _cachedMasterKey;

  KeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// 初始化：获取或生成主密钥
  Future<void> initialize() async {
    _cachedMasterKey = await _secureStorage.read(key: _masterKeyStorageKey);
    if (_cachedMasterKey == null) {
      _cachedMasterKey = EncryptionService.generateRandomKey();
      await _secureStorage.write(
        key: _masterKeyStorageKey,
        value: _cachedMasterKey,
      );
    }
  }

  /// 获取主密钥
  String get _masterKey {
    if (_cachedMasterKey == null) {
      throw StateError('KeyManager not initialized. Call initialize() first.');
    }
    return _cachedMasterKey!;
  }

  /// 加密 API Key
  String encryptApiKey(String apiKey) {
    return EncryptionService.encrypt(apiKey, _masterKey);
  }

  /// 解密 API Key
  String decryptApiKey(String encryptedApiKey) {
    return EncryptionService.decrypt(encryptedApiKey, _masterKey);
  }

  /// 加密一组交易所凭证
  Map<String, String> encryptCredentials({
    required String apiKey,
    required String apiSecret,
    String? passphrase,
  }) {
    return {
      'apiKey': encryptApiKey(apiKey),
      'apiSecret': encryptApiKey(apiSecret),
      if (passphrase != null) 'passphrase': encryptApiKey(passphrase),
    };
  }

  /// 解密一组交易所凭证
  Map<String, String> decryptCredentials({
    required String encryptedApiKey,
    required String encryptedSecret,
    String? encryptedPassphrase,
  }) {
    return {
      'apiKey': decryptApiKey(encryptedApiKey),
      'apiSecret': decryptApiKey(encryptedSecret),
      if (encryptedPassphrase != null)
        'passphrase': decryptApiKey(encryptedPassphrase),
    };
  }

  /// 清除所有密钥（重置应用时使用）
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _masterKeyStorageKey);
    _cachedMasterKey = null;
  }

  /// 检查是否已初始化
  bool get isInitialized => _cachedMasterKey != null;
}
