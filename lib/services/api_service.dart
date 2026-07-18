import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://lifeos.cadinindiyari.com/api";

  // Kayıt Ol
  static Future<Map<String, dynamic>> register({
    required String fullname,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullname": fullname,
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // Giriş Yap
  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"login": login, "password": password}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
