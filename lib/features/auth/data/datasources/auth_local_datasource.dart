import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';

/// Contract for persisting and reading auth credentials locally.
abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> readUser();
  Future<void> clearSession();
}

/// Concrete implementation backed by [FlutterSecureStorage].
///
/// Key names deliberately match those used by the legacy [AuthStorage] so both
/// share the same platform storage during the incremental refactor.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  static const _flavor = String.fromEnvironment('APP_FLAVOR');
  static final _tokenKey = _flavor.isEmpty ? 'auth_token' : 'auth_token_$_flavor';
  static final _userKey = _flavor.isEmpty ? 'auth_user' : 'auth_user_$_flavor';
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveToken(String token) {
    return _storage.write(
      key: _tokenKey,
      value: token,
      aOptions: _androidOptions,
    );
  }

  @override
  Future<String?> readToken() {
    return _storage.read(key: _tokenKey, aOptions: _androidOptions);
  }

  @override
  Future<void> saveUser(UserModel user) {
    return _storage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
      aOptions: _androidOptions,
    );
  }

  @override
  Future<UserModel?> readUser() async {
    final raw = await _storage.read(key: _userKey, aOptions: _androidOptions);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey, aOptions: _androidOptions);
    await _storage.delete(key: _userKey, aOptions: _androidOptions);
  }
}
