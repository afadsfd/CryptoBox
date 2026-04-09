import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'key_manager.dart';

/// KeyManager 单例 Provider
final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager();
});
