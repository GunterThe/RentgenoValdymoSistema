import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  FlutterSecureStorage? _secureStorage;
  Future<SharedPreferences>? _prefsFuture;

  FlutterSecureStorage get _storage =>
      _secureStorage ??= const FlutterSecureStorage(aOptions: AndroidOptions());

  Future<SharedPreferences> get _prefs =>
      _prefsFuture ??= SharedPreferences.getInstance();

  AuthTokens? _cache;

  Future<AuthTokens?> read() async {
    if (_cache != null) return _cache;

    final (access, refresh) = await _readRaw();
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return null;
    }

    _cache = AuthTokens(accessToken: access, refreshToken: refresh);
    return _cache;
  }

  Future<void> write(AuthTokens tokens) async {
    _cache = tokens;
    await _writeRaw(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
  }

  Future<void> clear() async {
    _cache = null;
    await _deleteRaw();
  }

  Future<(String?, String?)> _readRaw() async {
    if (kIsWeb) {
      try {
        final prefs = await _prefs;
        return (prefs.getString(_kAccess), prefs.getString(_kRefresh));
      } catch (_) {
        return (null, null);
      }
    }

    try {
      final access = await _storage.read(key: _kAccess);
      final refresh = await _storage.read(key: _kRefresh);
      return (access, refresh);
    } on PlatformException {
      // Happens in widget tests / unsupported platforms.
      return (null, null);
    } on MissingPluginException {
      return (null, null);
    }
  }

  Future<void> _writeRaw({required String accessToken, required String refreshToken}) async {
    if (kIsWeb) {
      try {
        final prefs = await _prefs;
        await prefs.setString(_kAccess, accessToken);
        await prefs.setString(_kRefresh, refreshToken);
      } catch (_) {}
      return;
    }

    try {
      await _storage.write(key: _kAccess, value: accessToken);
      await _storage.write(key: _kRefresh, value: refreshToken);
    } on PlatformException {
      // Ignore: plugin not available (e.g., tests).
    } on MissingPluginException {
      // Ignore: plugin not available (e.g., tests).
    }
  }

  Future<void> _deleteRaw() async {
    if (kIsWeb) {
      try {
        final prefs = await _prefs;
        await prefs.remove(_kAccess);
        await prefs.remove(_kRefresh);
      } catch (_) {}
      return;
    }

    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
    } on PlatformException {
      // Ignore: plugin not available (e.g., tests).
    } on MissingPluginException {
      // Ignore: plugin not available (e.g., tests).
    }
  }
}
