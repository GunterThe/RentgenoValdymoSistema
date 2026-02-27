import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class Api {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';

    final access = await AuthService.instance.getValidAccessToken();
    if (access != null && access.isNotEmpty) {
      h['Authorization'] = 'Bearer $access';
    }
    return h;
  }

  static Future<http.Response> _requestWithRefresh(
    Future<http.Response> Function(Map<String, String> headers) makeRequest,
  ) async {
    var headers = await _headers();
    var res = await makeRequest(headers);
    if (res.statusCode != 401) return res;

    // Force refresh and retry once.
    await AuthService.instance.refreshTokens();
    headers = await _headers();
    res = await makeRequest(headers);
    if (res.statusCode != 401) return res;

    await AuthService.instance.logout();
    return res;
  }

  static Uri prisegtasFailasFileUri(String id) {
    return Uri.parse('$baseUrl/api/prisegtasfailas/file/$id');
  }

  static Uri prisegtasFailasDownloadUri(String id) {
    return Uri.parse('$baseUrl/api/prisegtasfailas/download/$id');
  }
  // Irašai
  static Future<List<dynamic>> fetchIrasai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/irasas'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load irasai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createIrasas(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/irasas'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) throw Exception('Failed to create irasas');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateIrasas(int id, Map<String, dynamic> payload) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/irasas/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) throw Exception('Failed to update irasas');
  }

  static Future<void> deleteIrasas(int id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(Uri.parse('$baseUrl/api/irasas/$id'), headers: h),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete irasas');
  }

  // Testai
  static Future<List<dynamic>> fetchTestai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/testas'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load testai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createTestas(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/testas'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) throw Exception('Failed to create testas');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateTestas(int id, Map<String, dynamic> payload) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/testas/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) throw Exception('Failed to update testas');
  }

  static Future<void> deleteTestas(int id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(Uri.parse('$baseUrl/api/testas/$id'), headers: h),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete testas');
  }

  // TestasIrasas (ryšys)
  static Future<List<dynamic>> fetchTestasIrasai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/testasirasas'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load testasirasai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createTestasIrasas(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/testasirasas'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) throw Exception('Failed to create testasirasas');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateTestasIrasas(
    int testasid,
    int irasasid,
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/testasirasas/$testasid/$irasasid'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) throw Exception('Failed to update testasirasas');
  }

  static Future<void> deleteTestasIrasas(int testasid, int irasasid) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(
        Uri.parse('$baseUrl/api/testasirasas/$testasid/$irasasid'),
        headers: h,
      ),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete testasirasas');
  }

  // Prisegti failai
  static Future<List<dynamic>> fetchPrisegtiFailaiByIrasas(int irasasid) async {
    final res = await _requestWithRefresh(
      (h) => http.get(
        Uri.parse('$baseUrl/api/prisegtasfailas/byIrasas/$irasasid'),
        headers: h,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load prisegti failai');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> uploadPrisegtasFailas({
    required int irasasid,
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/prisegtasfailas/upload/$irasasid');

    Future<http.StreamedResponse> sendOnce() async {
      final req = http.MultipartRequest('POST', uri);
      final headers = await _headers();
      req.headers.addAll(headers);

      if (bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );
      } else if (filePath != null) {
        req.files.add(
          await http.MultipartFile.fromPath('file', filePath, filename: fileName),
        );
      } else {
        throw ArgumentError('Either bytes or filePath must be provided');
      }

      return req.send();
    }

    var streamed = await sendOnce();
    if (streamed.statusCode == 401) {
      await AuthService.instance.refreshTokens();
      streamed = await sendOnce();
      if (streamed.statusCode == 401) {
        await AuthService.instance.logout();
      }
    }

    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 201) {
      throw Exception('Failed to upload file (${streamed.statusCode}): $body');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  static Future<void> deletePrisegtasFailas(String id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(
        Uri.parse('$baseUrl/api/prisegtasfailas/$id'),
        headers: h,
      ),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete prisegtas failas');
  }

  // ZingsnisTemplate
  static Future<List<dynamic>> fetchZingsnisTemplates() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/zingsnistemplate'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load zingsnis templates');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createZingsnisTemplate(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/zingsnistemplate'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) throw Exception('Failed to create zingsnis template');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateZingsnisTemplate(int id, Map<String, dynamic> payload) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/zingsnistemplate/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) throw Exception('Failed to update zingsnis template');
  }

  static Future<void> deleteZingsnisTemplate(int id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(Uri.parse('$baseUrl/api/zingsnistemplate/$id'), headers: h),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete zingsnis template');
  }

  // Zingsnis (vykdymas)
  static Future<List<dynamic>> fetchZingsniai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/zingsnis'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load zingsniai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createZingsnis(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/zingsnis'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) throw Exception('Failed to create zingsnis');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateZingsnis(int id, Map<String, dynamic> payload) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/zingsnis/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) throw Exception('Failed to update zingsnis');
  }

  static Future<void> deleteZingsnis(int id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(Uri.parse('$baseUrl/api/zingsnis/$id'), headers: h),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete zingsnis');
  }
}
