import 'dart:convert';
import 'dart:math'; // For Random
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart'
    as enc; // Alias to avoid conflict with crypto
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PasswordEncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyStorageKey =
      'password_field_encryption_key';

  enc.Key? _key;
  enc.Encrypter? _encrypter;

  Future<void> _init() async {
    if (_key != null && _encrypter != null) return;

    String? keyBase64 = await _secureStorage.read(
      key: _encryptionKeyStorageKey,
    );
    if (keyBase64 == null) {
      // Generate a new 256-bit (32-byte) key
      final random = Random.secure();
      _key = enc.Key(
        Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256))),
      );
      await _secureStorage.write(
        key: _encryptionKeyStorageKey,
        value: _key!.base64,
      );
    } else {
      _key = enc.Key.fromBase64(keyBase64);
    }
    // Using AES-GCM for authenticated encryption
    _encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.gcm));
  }

  Future<Map<String, String>> encryptPassword(String plainPassword) async {
    await _init();
    // GCM mode requires a unique IV (Initialization Vector) for each encryption
    // 12 bytes (96 bits) is a common size for GCM IVs
    final iv = enc.IV.fromSecureRandom(12);
    final encrypted = _encrypter!.encrypt(plainPassword, iv: iv);
    return {
      'encryptedText': encrypted.base64,
      'ivBase64': iv.base64,
    };
  }

  Future<String> decryptPassword(
    String encryptedPasswordBase64,
    String ivBase64,
  ) async {
    await _init();
    final iv = enc.IV.fromBase64(ivBase64);
    final encrypted = enc.Encrypted.fromBase64(encryptedPasswordBase64);
    return _encrypter!.decrypt(encrypted, iv: iv);
  }
}
