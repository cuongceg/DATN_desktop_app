import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

class AuthStorage {
  const AuthStorage(this._storage);

  static const tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _defaultOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) {
    return _storage.write(
      key: tokenKey,
      value: token,
      aOptions: _defaultOptions,
    );
  }

  Future<String?> readToken() {
    return _storage.read(key: tokenKey, aOptions: _defaultOptions);
  }

  Future<void> saveUser(User user) {
    return _storage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
      aOptions: _defaultOptions,
    );
  }

  Future<User?> readUser() async {
    final rawUser = await _storage.read(
      key: _userKey,
      aOptions: _defaultOptions,
    );
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final data = jsonDecode(rawUser);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return User.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken() {
    return _storage.delete(key: tokenKey, aOptions: _defaultOptions);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: tokenKey, aOptions: _defaultOptions);
    await _storage.delete(key: _userKey, aOptions: _defaultOptions);
  }
}
