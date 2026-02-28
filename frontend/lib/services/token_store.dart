import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });
}

class TokenStore {
  static const _kAccess = 'auth.accessToken';
  static const _kRefresh = 'auth.refreshToken';

  TokenStore._();

  static final TokenStore instance = TokenStore._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  AuthTokens? _cache;

  Future<AuthTokens?> read() async {
    if (_cache != null) return _cache;

    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return null;
    }

    _cache = AuthTokens(accessToken: access, refreshToken: refresh);
    return _cache;
  }

  Future<void> write(AuthTokens tokens) async {
    _cache = tokens;
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    _cache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
