import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ADD THIS

// --- Page Imports ---
import 'home_page.dart';
import 'teacher_homepage.dart';
import 'admin_homepage.dart';
import 'staff_homepage.dart';
import 'student_homepage.dart';
import 'forgot_password_page.dart';
import 'api_service.dart';

const maroonColor = Color(0xFFA4123F);
const goldColor = Color(0xFFD4AF37);

// --- 1. NOTIFICATION CHANNEL SETUP ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Define the Android Channel (High Importance for Heads-up Display)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

// --- 2. BACKGROUND HANDLER (Must be top-level) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: null,
      macOS: null,
      linux: null,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // Create the channel on the device (Android)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e) {
    print("Firebase / Local Notification initialization failed: $e");
  }

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
  Widget? _startPage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadTheme();
    await _setupNotifications();
    await _checkAutoLogin(); // Check if user is already logged in
  }

  // --- 3. NOTIFICATION LOGIC (FOREGROUND) ---
  Future<void> _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // A. Request Permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // B. Get Token & Sync with Backend (CRITICAL FIX)
      try {
        String? token = await messaging.getToken();
        if (token != null) {
          print("FCM Token on Startup: $token");
          // We only sync if logged in, handled inside _checkAutoLogin or Login
        }
      } catch (e) {
        print("Error getting FCM token on startup: $e");
      }
    }

    // C. Handle Foreground Messages (Show Banner)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        // Show local notification (Banner)
        final androidDetails = AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher', // Ensure you have an icon resource
          importance: Importance.max,
          priority: Priority.high,
          color: maroonColor,
        );

        final platformDetails = NotificationDetails(android: androidDetails);

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformDetails,
        );
      }
    });
  }

  // --- 4. AUTO-LOGIN LOGIC ---
  Future<void> _checkAutoLogin() async {
    try {
      final token = await ApiService.readToken();
      final user = await ApiService.readUserProfile();

      if (token != null && user != null) {
        // User is logged in. Sync FCM Token now!
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await ApiService.updateFcmToken(fcmToken);
            print("✅ FCM Token auto-synced on startup");
          }
        } catch (e) {
          print("⚠️ Auto-sync FCM failed: $e");
        }

        // Determine Page
        final role = (user['role'] as String?)?.toLowerCase() ?? 'student';
        _startPage = _getPageForRole(role, user);
      } else {
        // Not logged in
        _startPage = LoginPage(onToggleTheme: _toggleTheme, isDark: _isDark);
      }
    } catch (e) {
      _startPage = LoginPage(onToggleTheme: _toggleTheme, isDark: _isDark);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _getPageForRole(String role, Map<String, dynamic> user) {
    final name = user['name'] ?? 'User';
    final email = user['email'] ?? '';
    final branch = user['branch'] ?? 'N/A';
    final section = user['section'] ?? 'N/A';
    final semester = user['semester'];
    final id = user['id'] ?? user['_id'];
    final profile = user['profile']; // Assuming profile is stored as string URL

    if (role == 'teacher') {
      return TeacherHomePage(
        universityName: "Amrita - Teacher",
        userName: name,
        userEmail: email,
        userId: id,
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      );
    } else if (role == 'admin') {
      return AdminHomePage(
        universityName: "Amrita - Admin",
        userName: name,
        userEmail: email,
        profile: profile,
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      );
    } else if (role == 'classrep') {
      return HomePage(
        universityName: "Amrita - CR",
        userName: name,
        userEmail: email,
        profile: profile,
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
        branch: branch,
        section: section,
        semester: semester,
      );
    }
    // Default Student
    return StudentHomePage(
      universityName: "Amrita - Student",
      userName: name,
      userEmail: email,
      profile: profile,
      isDark: _isDark,
      onToggleTheme: _toggleTheme,
      branch: branch,
      section: section,
      semester: semester,
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('theme_dark') ?? false;
    if (mounted) setState(() => _isDark = saved);
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
          backgroundColor: Color(0xFF1a0a14),
          body: Center(child: CircularProgressIndicator(color: goldColor)),
        ),
      );
    }

    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB), brightness: Brightness.light),
      useMaterial3: true,
    );
    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB), brightness: Brightness.dark),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: _startPage ?? LoginPage(onToggleTheme: _toggleTheme, isDark: _isDark),
    );
  }
}

// -----------------------------------------------------------------------------
// Keep your LoginPage class and _FloatingOrb class exactly as they were
// (from your original file). Paste them below — unchanged.
// -----------------------------------------------------------------------------

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

  bool _loading = false;

  // Helper method to create floating orbs
  List<Widget> _buildFloatingOrbs() {
    return [
      Positioned(
        top: -50,
        left: -50,
        child: _FloatingOrb(size: 200, color: const Color(0xFFD4AF37).withOpacity(0.1)),
      ),
      Positioned(
        top: 100,
        right: -30,
        child: _FloatingOrb(size: 150, color: const Color(0xFFA4123F).withOpacity(0.2)),
      ),
      Positioned(
        bottom: -80,
        right: 50,
        child: _FloatingOrb(size: 250, color: const Color(0xFFD4AF37).withOpacity(0.15)),
      ),
      Positioned(
        bottom: 100,
        left: -40,
        child: _FloatingOrb(size: 180, color: Colors.white.withOpacity(0.05)),
      ),
    ];
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Call API Login
      final res = await ApiService.login(email, password);

      // 2. Extract User Data
      final user = res['user'] as Map<String, dynamic>? ?? {};

      // --- 3. SYNC FCM TOKEN (New Feature) ---
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true, badge: true, sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          String? token = await messaging.getToken();
          if (token != null) {
            // Send Token to Backend to link it with this user
            await ApiService.updateFcmToken(token);
          }
        }
      } catch (e) {
        print("FCM Token Sync Error: $e");
        // Don't block login if FCM fails
      }
      // -------------------------------------

      // 4. Parse Role & Details
      final rawRole = (user['role'] as String?)?.trim().toLowerCase() ?? '';
      final role = rawRole.isEmpty ? 'student' : rawRole;

      final userName = user['name'] ?? user['email'] ?? 'User';
      final userEmail = user['email'] ?? '';
      final branch = user['branch'] ?? 'N/A';
      final section = user['section'] ?? 'N/A';
      final semester = user['semester'];

      // Critical: User ID for Teacher features
      final userId = user['id'] ?? user['_id'];

      final String? profile = (user['profile'] != null && user['profile'].toString().isNotEmpty)
          ? user['profile'].toString()
          : null;

      // 5. Determine Destination Page
      Widget targetPage;

      if (role == 'teacher') {
        targetPage = TeacherHomePage(
          universityName: "Amrita Vishwa Vidyapeetham — Teacher",
          userName: userName,
          userEmail: userEmail,
          userId: userId, // ✅ Passed ID specifically for Teacher
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      } else if (role == 'staff') {
        targetPage = StaffHomePage(
          universityName: "Amrita Vishwa Vidyapeetham — Staff",
          userName: userName,
          userEmail: userEmail,
          profile: profile,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      } else if (role == 'admin') {
        targetPage = AdminHomePage(
          universityName: "Amrita Vishwa Vidyapeetham — Admin",
          userName: userName,
          userEmail: userEmail,
          profile: profile,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
        );
      } else if (role == 'classrep') {
        targetPage = HomePage(
          universityName: _getUniversityNameForRole(role),
          userName: userName,
          userEmail: userEmail,
          profile: profile,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          branch: branch,
          section: section,
          semester: semester,
        );
      } else {
        // Default: Student
        targetPage = StudentHomePage(
          universityName: _getUniversityNameForRole(role),
          userName: userName,
          userEmail: userEmail,
          profile: profile,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          branch: branch,
          section: section,
          semester: semester,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetPage),
        );
      }
    } catch (e) {
      if (mounted) {
        // Clean up exception message
        final msg = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getUniversityNameForRole(String role) {
    switch (role) {
      case 'admin':
        return "Amrita Vishwa Vidyapeetham — Admin";
      case 'classrep':
      case 'class_rep':
      case 'cr':
        return "Amrita Vishwa Vidyapeetham — CR";
      case 'staff':
        return "Amrita Vishwa Vidyapeetham — Staff";
      default:
        return "Amrita Vishwa Vidyapeetham";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a0a14),
              maroonColor,
              const Color(0xFF5a1035),
              maroonColor.withOpacity(0.8),
              const Color(0xFF2d0a1f),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background Orbs
            ..._buildFloatingOrbs(),

            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Circle
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/Untitled design.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.school,
                              size: 100,
                              color: goldColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Welcome Text
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: maroonColor.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Glassmorphic Login Card
                        Container(
                          constraints: const BoxConstraints(maxWidth: 450),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Email Field
                                      TextFormField(
                                        controller: _emailController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: "Email",
                                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                          prefixIcon: const Icon(Icons.email_outlined, color: goldColor),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) => value!.isEmpty ? "Enter email" : null,
                                      ),
                                      const SizedBox(height: 20),

                                      // Password Field
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: "Password",
                                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                          prefixIcon: const Icon(Icons.lock_outline, color: goldColor),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) => value!.isEmpty ? "Enter password" : null,
                                      ),

                                      const SizedBox(height: 30),

                                      // Login Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _loading ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: maroonColor,
                                            foregroundColor: Colors.white,
                                            elevation: 8,
                                            shadowColor: maroonColor.withOpacity(0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                          ),
                                          child: _loading
                                              ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                              : const Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Forgot Password
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                          );
                                        },
                                        child: const Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated floating orb widget
class _FloatingOrb extends StatefulWidget {
  final double size;
  final Color color;

  const _FloatingOrb({required this.size, required this.color});

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            20 * _controller.value,
            30 * (1 - _controller.value),
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color,
                  widget.color.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
