import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'jwt_utils.dart';
import 'token_store.dart';

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final TokenStore _store = TokenStore.instance;

  AuthTokens? _tokens;
  bool _initialized = false;
  Future<void>? _refreshInFlight;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _tokens != null;

  String? get accessToken => _tokens?.accessToken;

  String? get currentUserId {
    final jwt = _tokens?.accessToken;
    if (jwt == null || jwt.isEmpty) return null;
    return JwtUtils.tryGetSubject(jwt);
  }

  bool get isAdmin {
    final jwt = _tokens?.accessToken;
    if (jwt == null || jwt.isEmpty) return false;
    final admin = (JwtUtils.tryGetClaim(jwt, 'admin') ?? '').trim();
    return admin.toLowerCase() == 'true';
  }

  bool get isSuperAdmin {
    final jwt = _tokens?.accessToken;
    if (jwt == null || jwt.isEmpty) return false;
    final superAdmin = (JwtUtils.tryGetClaim(jwt, 'superadmin') ?? '').trim();
    return superAdmin.toLowerCase() == 'true';
  }

  String get displayName {
    final jwt = _tokens?.accessToken;
    if (jwt == null || jwt.isEmpty) return '';
    final vardas = (JwtUtils.tryGetClaim(jwt, 'vardas') ?? '').trim();
    final pavarde = (JwtUtils.tryGetClaim(jwt, 'pavarde') ?? '').trim();
    if (vardas.isEmpty && pavarde.isEmpty) return '';
    if (vardas.isEmpty) return pavarde;
    if (pavarde.isEmpty) return vardas;
    return '$vardas $pavarde';
  }

  String get prisijungimoId {
    final jwt = _tokens?.accessToken;
    if (jwt == null || jwt.isEmpty) return '';
    return (JwtUtils.tryGetClaim(jwt, 'email') ?? '').trim();
  }

  Future<void> init() async {
    _tokens = await _store.read();

    if (_tokens != null && JwtUtils.isExpired(_tokens!.accessToken)) {
      await _tryRefresh();
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> login({
    required String prisijungimoId,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');
    final res = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prisijungimoId': prisijungimoId,
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Login failed (${res.statusCode}): ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final access = body['accessToken'] as String?;
    final refresh = body['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw Exception('Login response missing tokens');
    }

    final tokens = AuthTokens(accessToken: access, refreshToken: refresh);
    _tokens = tokens;
    await _store.write(tokens);
    notifyListeners();
  }

  Future<void> logout() async {
    final refresh = _tokens?.refreshToken;
    if (refresh != null) {
      try {
        await _revoke(refresh);
      } catch (_) {}
    }

    _tokens = null;
    await _store.clear();
    notifyListeners();
  }

  Future<String?> getValidAccessToken() async {
    if (_tokens == null) return null;

    if (!JwtUtils.isExpired(_tokens!.accessToken)) {
      return _tokens!.accessToken;
    }

    await _tryRefresh();
    return _tokens?.accessToken;
  }

  Future<void> refreshTokens() async {
    if (_tokens == null) return;
    await _tryRefresh();
  }

  Future<void> _tryRefresh() async {
    _refreshInFlight ??= _refresh();
    try {
      await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _refresh() async {
    final refreshToken = _tokens?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      _tokens = null;
      await _store.clear();
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh');
    final res = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (res.statusCode != 200) {
      _tokens = null;
      await _store.clear();
      notifyListeners();
      return;
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final access = body['accessToken'] as String?;
    final refresh = body['refreshToken'] as String?;
    if (access == null || refresh == null) {
      _tokens = null;
      await _store.clear();
      notifyListeners();
      return;
    }

    final tokens = AuthTokens(accessToken: access, refreshToken: refresh);
    _tokens = tokens;
    await _store.write(tokens);
    notifyListeners();
  }

  Future<void> _revoke(String refreshToken) async {
    final access = await getValidAccessToken();
    if (access == null) return;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/revoke');
    await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $access',
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );
  }
}
