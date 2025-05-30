import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String password) {
  final bytes = utf8.encode(password); // data being hashed
  final digest = sha256.convert(bytes);
  return digest.toString();
}
