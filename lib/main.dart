// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'auth_service.dart';

const maroonColor = Color(0xFFA4123F);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RootApp());
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _isDark = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('theme_dark') ?? false;
    setState(() {
      _isDark = saved;
      _loading = false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', value);
    setState(() => _isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: LoginPage(
        onToggleTheme: _toggleTheme, // passed to HomePage later
        isDark: _isDark,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const LoginPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  bool _loading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final res = await _auth.login(email, password);
      if (res['ok'] == true) {
        final user = res['user'] as Map<String, dynamic>?;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              universityName: "Amrita Vishwa Vidyapeetham",
              userName: user?['name'] ?? user?['email'],
              userEmail: user?['email'],
              isDark: widget.isDark,
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        );
      } else {
        final err = res['error'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maroonColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 20),
                    const Text("Login",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: maroonColor)),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      validator: (value) => value!.isEmpty ? "Enter email" : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                      validator: (value) => value!.isEmpty ? "Enter password" : null,
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroonColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
