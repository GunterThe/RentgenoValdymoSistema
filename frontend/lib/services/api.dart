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

  // Žinutės
  static Future<Map<String, dynamic>> sendMessageToAdmins({
    required String tekstas,
  }) async {
    final t = tekstas.trim();
    if (t.isEmpty) {
      throw Exception('Tekstas yra būtinas');
    }

    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/Zinute/sendToAdmins'),
        headers: headers,
        body: jsonEncode({'tekstas': t}),
      );
    });

    if (res.statusCode != 201) {
      throw Exception(
        'Failed to send message (${res.statusCode}): ${res.body}',
      );
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> fetchZinutes() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/Zinute'), headers: h),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load zinutes (${res.statusCode})');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> fetchMyInboxZinutes() async {
    final res = await _requestWithRefresh(
      (h) =>
          http.get(Uri.parse('$baseUrl/api/NaudotojasZinute/my'), headers: h),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load inbox (${res.statusCode})');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> markInboxZinuteRead({
    required int zinuteId,
    required bool perskaityta,
  }) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Missing current user id');
    }

    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/NaudotojasZinute/$userId/$zinuteId'),
        headers: headers,
        body: jsonEncode({'perskaityta': perskaityta}),
      );
    });

    if (res.statusCode != 204) {
      throw Exception(
        'Failed to update inbox item (${res.statusCode}): ${res.body}',
      );
    }
  }

  static Future<void> deleteInboxZinute({required int zinuteId}) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Missing current user id');
    }

    final res = await _requestWithRefresh(
      (h) => http.delete(
        Uri.parse('$baseUrl/api/NaudotojasZinute/$userId/$zinuteId'),
        headers: h,
      ),
    );

    if (res.statusCode != 204) {
      throw Exception(
        'Failed to delete inbox item (${res.statusCode}): ${res.body}',
      );
    }
  }

  // Naudotojai
  static Future<Map<String, dynamic>> fetchNaudotojas(String id) async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/Naudotojas/$id'), headers: h),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load naudotojas');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> fetchNaudotojai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/Naudotojas'), headers: h),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load naudotojai (${res.statusCode})');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> adminCreateNaudotojas({
    required String vardas,
    required String pavarde,
    required DateTime gimimoData,
    required bool adminas,
    required String password,
  }) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/Naudotojas'),
        headers: headers,
        body: jsonEncode({
          'vardas': vardas,
          'pavarde': pavarde,
          'gimimoData': gimimoData.toIso8601String(),
          'adminas': adminas,
          'password': password,
        }),
      );
    });

    if (res.statusCode != 201) {
      throw Exception(
        'Failed to create naudotojas (${res.statusCode}): ${res.body}',
      );
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/Naudotojas/changePassword/$userId'),
        headers: headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
    });
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to change password (${res.statusCode}): ${res.body}',
      );
    }
  }

  static Future<void> adminSetPassword({
    required String userId,
    required String newPassword,
  }) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/Naudotojas/setPassword/$userId'),
        headers: headers,
        body: jsonEncode({'newPassword': newPassword}),
      );
    });
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to set password (${res.statusCode}): ${res.body}',
      );
    }
  }

  static Future<void> superAdminToggleAdmin({required String userId}) async {
    final res = await _requestWithRefresh((h) {
      return http.put(
        Uri.parse('$baseUrl/api/Naudotojas/toggleAdmin/$userId'),
        headers: h,
      );
    });
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to toggle admin (${res.statusCode}): ${res.body}',
      );
    }
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

  // TestasIrasas -> privalomi vartų žingsniai
  static Future<List<dynamic>> fetchTestasIrasasPrivalomiZingsniai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(
        Uri.parse('$baseUrl/api/testasirasasprivalomaszingsnistemplate'),
        headers: h,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load testasirasas privalomi zingsniai (${res.statusCode}): ${res.body}',
      );
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> setTestasIrasasPrivalomiZingsniai(
    int testasIrasasId,
    List<int> zingsnisTemplateIds,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse(
          '$baseUrl/api/testasirasasprivalomaszingsnistemplate/$testasIrasasId',
        ),
        headers: headers,
        body: jsonEncode({'zingsnisTemplateIds': zingsnisTemplateIds}),
      );
    });
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to set privalomi zingsniai (${res.statusCode}): ${res.body}',
      );
    }
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

  // Lokacija
  static Future<List<dynamic>> fetchLokacijos() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/lokacija'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load lokacijos');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createLokacija(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/lokacija'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) throw Exception('Failed to create lokacija');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateLokacija(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/lokacija/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) throw Exception('Failed to update lokacija');
  }

  static Future<void> deleteLokacija(int id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(Uri.parse('$baseUrl/api/lokacija/$id'), headers: h),
    );
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to delete lokacija (${res.statusCode}): ${res.body}',
      );
    }
  }

  // Sablonas
  static Future<List<dynamic>> fetchSablonai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/sablonas'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load sablonai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createSablonas(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/sablonas'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) throw Exception('Failed to create sablonas');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateSablonas(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/sablonas/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) throw Exception('Failed to update sablonas');
  }

  static Future<void> deleteSablonas(int id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(Uri.parse('$baseUrl/api/sablonas/$id'), headers: h),
    );
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to delete sablonas (${res.statusCode}): ${res.body}',
      );
    }
  }

  // SablonasTestas (ryšys)
  static Future<List<dynamic>> fetchSablonasTestai() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/sablonastestas'), headers: h),
    );
    if (res.statusCode != 200) throw Exception('Failed to load sablonastestai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createSablonasTestas(
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.post(
        Uri.parse('$baseUrl/api/sablonastestas'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 201) {
      throw Exception(
        'Failed to create sablonastestas (${res.statusCode}): ${res.body}',
      );
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> deleteSablonasTestas(int sablonasId, int testasId) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(
        Uri.parse('$baseUrl/api/sablonastestas/$sablonasId/$testasId'),
        headers: h,
      ),
    );
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to delete sablonastestas (${res.statusCode}): ${res.body}',
      );
    }
  }

  static Future<void> updateSablonasTestas(
    int sablonasId,
    int testasId,
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/sablonastestas/$sablonasId/$testasId'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) {
      throw Exception(
        'Failed to update sablonastestas (${res.statusCode}): ${res.body}',
      );
    }
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

  static Future<void> deleteTestasIrasasById(int id) async {
    final res = await _requestWithRefresh(
      (h) =>
          http.delete(Uri.parse('$baseUrl/api/testasirasas/$id'), headers: h),
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
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: fileName,
          ),
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
    if (res.statusCode != 204) {
      throw Exception('Failed to delete prisegtas failas');
    }
  }

  static Future<List<dynamic>> fetchPrisegtiFailaiByZingsnis(
    int zingsnisId,
  ) async {
    final res = await _requestWithRefresh(
      (h) => http.get(
        Uri.parse('$baseUrl/api/prisegtasfailas/byZingsnis/$zingsnisId'),
        headers: h,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load prisegti failai');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> fetchPrisegtiFailaiByZingsnisTemplate(
    int templateId,
  ) async {
    final res = await _requestWithRefresh(
      (h) => http.get(
        Uri.parse(
          '$baseUrl/api/prisegtasfailas/byZingsnisTemplate/$templateId',
        ),
        headers: h,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load template files');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> uploadPrisegtasFailasToZingsnis({
    required int zingsnisId,
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/prisegtasfailas/upload/$zingsnisId');

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
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: fileName,
          ),
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

  static Future<Map<String, dynamic>> uploadPrisegtasFailasToZingsnisTemplate({
    required int templateId,
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/prisegtasfailas/uploadTemplate/$templateId',
    );

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
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: fileName,
          ),
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
      throw Exception(
        'Failed to upload template image (${streamed.statusCode}): $body',
      );
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ZingsnisTemplate
  static Future<List<dynamic>> fetchZingsnisTemplates() async {
    final res = await _requestWithRefresh(
      (h) => http.get(Uri.parse('$baseUrl/api/zingsnistemplate'), headers: h),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load zingsnis templates');
    }
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
    if (res.statusCode != 201) {
      throw Exception('Failed to create zingsnis template');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateZingsnisTemplate(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await _requestWithRefresh((h) {
      final headers = {...h, 'Content-Type': 'application/json'};
      return http.put(
        Uri.parse('$baseUrl/api/zingsnistemplate/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
    });
    if (res.statusCode != 204) {
      throw Exception('Failed to update zingsnis template');
    }
  }

  static Future<void> deleteZingsnisTemplate(int id) async {
    final res = await _requestWithRefresh(
      (h) => http.delete(
        Uri.parse('$baseUrl/api/zingsnistemplate/$id'),
        headers: h,
      ),
    );
    if (res.statusCode != 204) {
      throw Exception('Failed to delete zingsnis template');
    }
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

  static Future<void> updateZingsnis(
    int id,
    Map<String, dynamic> payload,
  ) async {
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
