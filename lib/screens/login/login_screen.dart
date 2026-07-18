import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';
import '../register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    if (loginController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final result = await ApiService.login(
      login: loginController.text.trim(),
      password: passwordController.text,
    );

    if (mounted) {
      setState(() {
        loading = false;
      });
    }

    if (!mounted) return;

    if (result["success"] == true) {
      await UserService.setUser(result["user"]);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]?.toString() ?? "Giriş başarısız."),
        ),
      );
    }
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const SizedBox(height: 20),

                Center(
                  child: Image.asset(
                    "assets/icon/pilife_logo.png",
                    width: 120,
                    height: 120,
                  ),
                ),

                const SizedBox(height: 25),

                const Center(
                  child: Text(
                    "PiLife",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B2D90),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    "Pi Network yaşam platformu",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 45),

                TextField(
                  controller: loginController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: "Kullanıcı Adı veya E-Posta",
                    prefixIcon: const Icon(Icons.person),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => login(),

                  decoration: InputDecoration(
                    hintText: "Şifre",
                    prefixIcon: const Icon(Icons.lock),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 55,

                  child: ElevatedButton(
                    onPressed: loading ? null : login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B2D90),
                      foregroundColor: Colors.white,
                    ),

                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "Giriş Yap",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },

                  child: const Text("Hesabın yok mu? Kayıt Ol"),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
