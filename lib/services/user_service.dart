import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static int id = 0;
  static String fullname = "";
  static String username = "";
  static String email = "";

  static Future<void> setUser(Map<String, dynamic> user) async {
    id = int.parse(user["id"].toString());
    fullname = user["fullname"] ?? "";
    username = user["username"] ?? "";
    email = user["email"] ?? "";

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("user_id", id);
    await prefs.setString("fullname", fullname);
    await prefs.setString("username", username);
    await prefs.setString("email", email);
  }

  static Future<bool> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    id = prefs.getInt("user_id") ?? 0;
    fullname = prefs.getString("fullname") ?? "";
    username = prefs.getString("username") ?? "";
    email = prefs.getString("email") ?? "";

    return id != 0;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    id = 0;
    fullname = "";
    username = "";
    email = "";
  }

  static bool get isLoggedIn => id != 0;
}
