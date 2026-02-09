import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  // Adjust baseUrl if your backend runs on a different port
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:5158',
  );

  // Irašai
  static Future<List<dynamic>> fetchIrasai() async {
    final res = await http.get(Uri.parse('$baseUrl/api/irasas'));
    if (res.statusCode != 200) throw Exception('Failed to load irasai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createIrasas(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/irasas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) throw Exception('Failed to create irasas');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateIrasas(int id, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/irasas/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 204) throw Exception('Failed to update irasas');
  }

  static Future<void> deleteIrasas(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/irasas/$id'));
    if (res.statusCode != 204) throw Exception('Failed to delete irasas');
  }

  // Testai
  static Future<List<dynamic>> fetchTestai() async {
    final res = await http.get(Uri.parse('$baseUrl/api/testas'));
    if (res.statusCode != 200) throw Exception('Failed to load testai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createTestas(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/testas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) throw Exception('Failed to create testas');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateTestas(int id, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/testas/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 204) throw Exception('Failed to update testas');
  }

  static Future<void> deleteTestas(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/testas/$id'));
    if (res.statusCode != 204) throw Exception('Failed to delete testas');
  }

  // TestasIrasas (ryšys)
  static Future<List<dynamic>> fetchTestasIrasai() async {
    final res = await http.get(Uri.parse('$baseUrl/api/testasirasas'));
    if (res.statusCode != 200) throw Exception('Failed to load testasirasai');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createTestasIrasas(
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/testasirasas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) throw Exception('Failed to create testasirasas');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateTestasIrasas(
    int testasid,
    int irasasid,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/testasirasas/$testasid/$irasasid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 204) throw Exception('Failed to update testasirasas');
  }

  static Future<void> deleteTestasIrasas(int testasid, int irasasid) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/testasirasas/$testasid/$irasasid'),
    );
    if (res.statusCode != 204) throw Exception('Failed to delete testasirasas');
  }
}
