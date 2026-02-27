import 'dart:convert';

class JwtUtils {
  static Map<String, dynamic>? _tryGetPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = _base64UrlDecode(parts[1]);
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static DateTime? tryGetExpiryUtc(String jwt) {
    final map = _tryGetPayload(jwt);
    if (map == null) return null;
    final exp = map['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      (exp * 1000).round(),
      isUtc: true,
    );
  }

  static String? tryGetClaim(String jwt, String claim) {
    final map = _tryGetPayload(jwt);
    if (map == null) return null;
    final v = map[claim];
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static String? tryGetSubject(String jwt) => tryGetClaim(jwt, 'sub');

  static bool isExpired(
    String jwt, {
    Duration skew = const Duration(seconds: 30),
    DateTime? nowUtc,
  }) {
    final exp = tryGetExpiryUtc(jwt);
    if (exp == null) return true;
    final now = nowUtc ?? DateTime.now().toUtc();
    return exp.isBefore(now.add(skew));
  }

  static String _base64UrlDecode(String input) {
    final normalized = base64Url.normalize(input);
    return utf8.decode(base64Url.decode(normalized));
  }
}
