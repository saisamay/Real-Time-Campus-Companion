import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Helper: header/profile gradient colors (same source for both areas)
List<Color> headerGradientColors(bool isDark) {
  // dark: grey -> black; light: your original mint/teal gradient
  return isDark
      ? [const Color(0xFF2D2D2D), const Color(0xFF0B0B0B)]
      : [const Color(0xFF06B6D4), const Color(0xFF06D6A0)];
}

// ----------------------- APP -----------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  void _toggleTheme(bool value) => setState(() => _isDark = value);

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      colorScheme:
      ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB), brightness: Brightness.light),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(height: 70, elevation: 2),
    );

    final dark = ThemeData(
      colorScheme:
      ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB), brightness: Brightness.dark),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(height: 70, elevation: 2),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University (Teachers)',
      theme: light,
      darkTheme: dark,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: TeachersHome(
        universityName: 'Your University Name',
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

// ----------------------- TEACHERS HOME -----------------------
class TeachersHome extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  const TeachersHome({super.key, required this.universityName, required this.isDark, required this.onToggleTheme});

  @override
  State<TeachersHome> createState() => _TeachersHomeState();
}

class _TeachersHomeState extends State<TeachersHome> {
  int _index = 0;
  late PageController _pageController;

  // Profile info
  String teacherName = 'Admin';
  String teacherEmail = 'admin@university.edu';
  String department = 'Admin';
   String cabin = 'Block A ';

  // simple in-memory password (for demo)
  String _password = 'password123';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() {
      _index = index;
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  // keep existing change password dialog — reused by ProfilePage callback
  Future<void> _showChangePasswordDialog(BuildContext ctx) async {
    final cur = TextEditingController();
    final nw = TextEditingController();
    final conf = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: cur, obscureText: true, decoration: const InputDecoration(labelText: 'Current password'), validator: (v) {
              if ((v ?? '').isEmpty) return 'Enter current password';
              if (v != _password) return 'Current password incorrect';
              return null;
            }),
            const SizedBox(height: 8),
            TextFormField(controller: nw, obscureText: true, decoration: const InputDecoration(labelText: 'New password'), validator: (v) {
              if ((v ?? '').length < 6) return 'Min 6 chars';
              return null;
            }),
            const SizedBox(height: 8),
            TextFormField(controller: conf, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password'), validator: (v) {
              if (v != nw.text) return 'Passwords do not match';
              return null;
            }),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              setState(() => _password = nw.text);
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password changed')));
            }
          }, child: const Text('Change')),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // AppBar: gradient header + theme toggle (replaced search)
      appBar: AppBar(
        title: Text(widget.universityName),
        leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())),
        actions: [
          // Theme toggle button in header (shows current mode and toggles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              tooltip: widget.isDark ? 'Switch to light' : 'Switch to dark',
              icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => widget.onToggleTheme(!widget.isDark),
            ),
          ),
        ],
        // add gradient colors to the app bar header (use helper)
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: headerGradientColors(widget.isDark),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const CircleAvatar(radius: 28, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5")),
                const SizedBox(height: 12),
                Text(teacherName, style: TextStyle(color: scheme.onPrimary, fontSize: 18)),
                Text(teacherEmail, style: TextStyle(color: scheme.onPrimary.withOpacity(.8), fontSize: 14)),
              ]),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () {
              Navigator.pop(context);
              _goToPage(0);
            }),
            ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () {
              Navigator.pop(context);
              _goToPage(1);
            }),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          const ClassroomsPage(),
          // ---------- use ProfilePage here, wired to existing state ----------
          ProfilePage(
            userName: teacherName,
            userEmail: teacherEmail,
            dept: department,
            section: cabin,
            isDark: widget.isDark,
            onToggleTheme: (v) => widget.onToggleTheme(v),
            onUpdateName: (newName) => setState(() => teacherName = newName),
            onUpdateEmail: (newEmail) => setState(() => teacherEmail = newEmail),
            initialPhotoUrl: null,
            onChangePhoto: () {
              // keep photo handling visual — you can replace with image picker
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Change photo tapped')));
            },
            onChangePassword: () => _showChangePasswordDialog(context),
            onLogout: () {
              showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                    FilledButton(onPressed: () {
                      Navigator.pop(dCtx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
                    }, child: const Text('Log Out')),
                  ],
                ),
              );
            },
            showAdminActions: true,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ------------------ PROFILE PAGE (copied from your provided code) ------------------
class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String dept;
  final String section;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateEmail;

  // --- New admin-related optional parameters (merged without logic changes) ---
  final String? initialPhotoUrl; // allow parent to provide profile image URL
  final VoidCallback? onChangePhoto; // called when "Change Photo" is pressed
  final VoidCallback? onChangePassword; // called when "Change Password" is pressed
  final VoidCallback? onLogout; // called when "Log out" is pressed
  final bool showAdminActions; // whether to show admin action tiles

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.dept,
    required this.section,
    this.isDark = false,
    this.onToggleTheme,
    this.onUpdateName,
    this.onUpdateEmail,
    // admin additions
    this.initialPhotoUrl,
    this.onChangePhoto,
    this.onChangePassword,
    this.onLogout,
    this.showAdminActions = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late String _name;
  late String _email;
  late bool _localIsDark; // local copy for immediate UI response
  late String _profileImage; // local copy for image fallback
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _email = widget.userEmail;
    _localIsDark = widget.isDark;
    _profileImage = widget.initialPhotoUrl ?? "https://i.pravatar.cc/150?img=3";

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      _localIsDark = widget.isDark;
    }
    if (oldWidget.initialPhotoUrl != widget.initialPhotoUrl && widget.initialPhotoUrl != null) {
      _profileImage = widget.initialPhotoUrl!;
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Edit Name'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _name = ctrl.text.trim());
      widget.onUpdateName?.call(_name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Name updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _editEmail() async {
    final ctrl = TextEditingController(text: _email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Edit Email'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _email = ctrl.text.trim());
      widget.onUpdateEmail?.call(_email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Email updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _changeProfileImage() {
    // call parent callback if provided, otherwise update locally (visual only)
    if (widget.onChangePhoto != null) {
      widget.onChangePhoto!.call();
      return;
    }
    setState(() {
      _profileImage = 'https://images.unsplash.com/photo-1525973132219-a04334a76080?auto=format&fit=crop&w=800&q=80';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Profile photo updated'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _changePasswordDialog() async {
    if (widget.onChangePassword != null) {
      widget.onChangePassword!.call();
      return;
    }
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Change Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text || newCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Passwords do not match'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Password changed successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutDialog() async {
    if (widget.onLogout != null) {
      widget.onLogout!.call();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Log out?'),
          ],
        ),
        content: const Text('Are you sure you want to sign out of this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Logged out successfully'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildInfoCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // <-- use same header gradient here (dark -> grey/black; light -> mint/teal)
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerGradientColors(isDark),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? headerGradientColors(isDark).first : const Color(0xFF00ACC1)).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'profile_image',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage: NetworkImage(_profileImage),
                        // Keep the avatar itself unchanged; the card background now follows header colors.
                      ),
                    ),
                  ),
                  if (widget.showAdminActions)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: widget.onChangePhoto ?? _changeProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.camera_alt, size: 18, color: cs.primary),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.dept} - ${widget.section}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.email, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (iconColor ?? cs.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor ?? cs.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _localIsDark ? Icons.dark_mode : Icons.light_mode,
              color: cs.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _localIsDark ? 'Dark mode enabled' : 'Light mode enabled',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _localIsDark,
            onChanged: (value) {
              setState(() => _localIsDark = value);
              widget.onToggleTheme?.call(value);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildInfoCard(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildActionCard(
                    context: context,
                    icon: Icons.person,
                    title: 'Edit Name',
                    subtitle: 'Update your display name',
                    onTap: _editName,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context: context,
                    icon: Icons.email,
                    title: 'Edit Email',
                    subtitle: 'Change your email address',
                    onTap: _editEmail,
                  ),
                  const SizedBox(height: 12),
                  _buildThemeCard(context),

                  if (widget.showAdminActions) ...[
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context: context,
                      icon: Icons.lock,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: widget.onChangePassword ?? _changePasswordDialog,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context: context,
                      icon: Icons.logout,
                      title: 'Log Out',
                      subtitle: 'Sign out of your account',
                      onTap: widget.onLogout ?? _logoutDialog,
                      iconColor: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ------------------ CLASSROOMS PAGE (responsive, debounced) ------------------
// (animated entry added; other features unchanged)
class ClassroomsPage extends StatefulWidget {
  const ClassroomsPage({super.key});

  @override
  State<ClassroomsPage> createState() => _ClassroomsPageState();
}

class _ClassroomsPageState extends State<ClassroomsPage> with SingleTickerProviderStateMixin {
  String selectedFloor = 'All Floors';
  String selectedType = 'All';
  String _searchQuery = '';
  Timer? _searchDebounce;

  // animation controller & tweens (added)
  late final AnimationController _entryController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Sample classroom data with occupancy status
  final List<Map<String, dynamic>> classrooms = [
    {
      'name': 'Room 101',
      'floor': '1st Floor',
      'capacity': 60,
      'occupied': true,
      'subject': 'Mathematics',
      'time': '9:00 AM - 10:00 AM',
      'type': 'Class',
    },
    {
      'name': 'Room 102',
      'floor': '1st Floor',
      'capacity': 50,
      'occupied': false,
      'subject': '',
      'time': '',
      'type': 'Class',
    },
    {
      'name': 'Room 103',
      'floor': '1st Floor',
      'capacity': 40,
      'occupied': true,
      'subject': 'Physics',
      'time': '10:00 AM - 11:00 AM',
      'type': 'Class',
    },
    {
      'name': 'Room 201',
      'floor': '2nd Floor',
      'capacity': 70,
      'occupied': false,
      'subject': '',
      'time': '',
      'type': 'Class',
    },
    {
      'name': 'Room 202',
      'floor': '2nd Floor',
      'capacity': 55,
      'occupied': true,
      'subject': 'Chemistry',
      'time': '11:00 AM - 12:00 PM',
      'type': 'Class',
    },
    {
      'name': 'Room 203',
      'floor': '2nd Floor',
      'capacity': 45,
      'occupied': false,
      'subject': '',
      'time': '',
      'type': 'Class',
    },
    {
      'name': 'Room 301',
      'floor': '3rd Floor',
      'capacity': 80,
      'occupied': true,
      'subject': 'Computer Science',
      'time': '2:00 PM - 3:00 PM',
      'type': 'Class',
    },
    {
      'name': 'Room 302',
      'floor': '3rd Floor',
      'capacity': 60,
      'occupied': false,
      'subject': '',
      'time': '',
      'type': 'Class',
    },
    {
      'name': 'Room 303',
      'floor': '3rd Floor',
      'capacity': 50,
      'occupied': true,
      'subject': 'English',
      'time': '3:00 PM - 4:00 PM',
      'type': 'Class',
    },
    {
      'name': 'Lab A',
      'floor': '1st Floor',
      'capacity': 30,
      'occupied': false,
      'subject': '',
      'time': '',
      'type': 'Lab',
    },
    {
      'name': 'Lab B',
      'floor': '2nd Floor',
      'capacity': 35,
      'occupied': true,
      'subject': 'Electronics Lab',
      'time': '1:00 PM - 3:00 PM',
      'type': 'Lab',
    },
    {
      'name': 'Computer Lab 1',
      'floor': '3rd Floor',
      'capacity': 40,
      'occupied': false,
      'subject': '',
      'time': '',
      'type': 'Lab',
    },
    {
      'name': 'Physics Lab',
      'floor': '2nd Floor',
      'capacity': 25,
      'occupied': true,
      'subject': 'Physics Practical',
      'time': '10:00 AM - 12:00 PM',
      'type': 'Lab',
    },
  ];

  @override
  void initState() {
    super.initState();

    // entry animations (same feel as ProfilePage)
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  // Debounced setter for search text
  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = text.trim());
    });
  }

  List<Map<String, dynamic>> get filteredClassrooms {
    final q = _searchQuery.toLowerCase();
    return classrooms.where((room) {
      final matchesFloor = selectedFloor == 'All Floors' || room['floor'] == selectedFloor;
      final matchesType = selectedType == 'All' || room['type'] == selectedType;
      final matchesSearch = q.isEmpty || (room['name'] as String).toLowerCase().contains(q);
      return matchesFloor && matchesType && matchesSearch;
    }).toList();
  }

  int get occupiedCount => filteredClassrooms.where((r) => r['occupied'] == true).length;
  int get availableCount => filteredClassrooms.where((r) => r['occupied'] == false).length;

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Filter by Type', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All', Icons.grid_view_rounded),
            const SizedBox(height: 12),
            _buildFilterOption('Class', Icons.class_rounded),
            const SizedBox(height: 12),
            _buildFilterOption('Lab', Icons.science_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String type, IconData icon) {
    final isSelected = selectedType == type;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!mounted) return;
        setState(() => selectedType = type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? scheme.primary : scheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 12),
            Text(
              type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? scheme.primary : scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: scheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ColorScheme scheme) {
    final isSelected = selectedFloor == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          if (!mounted) return;
          setState(() => selectedFloor = label);
        },
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildClassroomCard(BuildContext context, Map<String, dynamic> room) {
    final isOccupied = room['occupied'] as bool;
    final isLab = room['type'] == 'Lab';
    final statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showClassroomDetails(context, room),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.6)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(isLab ? Icons.science_rounded : (isOccupied ? Icons.door_front_door : Icons.meeting_room_outlined),
                        color: statusColor, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(isOccupied ? 'OCCUPIED' : 'AVAILABLE', style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const Spacer(),
                Text(room['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLab ? const Color(0xFFFF9800).withOpacity(0.15) : const Color(0xFF00ACC1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isLab ? Icons.science_rounded : Icons.class_rounded, size: 11, color: isLab ? const Color(0xFFFF9800) : const Color(0xFF00ACC1)),
                    const SizedBox(width: 3),
                    Text(room['type'], style: TextStyle(fontSize: 10, color: isLab ? const Color(0xFFFF9800) : const Color(0xFF00ACC1), fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(height: 5),
                Row(children: [Icon(Icons.layers, size: 12, color: scheme.onSurfaceVariant), const SizedBox(width: 3), Text(room['floor'], style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))]),
                const SizedBox(height: 3),
                Row(children: [Icon(Icons.people, size: 12, color: scheme.onSurfaceVariant), const SizedBox(width: 3), Text('${room['capacity']} seats', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))]),
                if (isOccupied && (room['subject'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: scheme.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(5)),
                    child: Text(room['subject'], style: TextStyle(fontSize: 10, color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showClassroomDetails(BuildContext context, Map<String, dynamic> room) {
    final isOccupied = room['occupied'] as bool;
    final statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: scheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: scheme.onSurfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Row(children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Icon(isOccupied ? Icons.door_front_door : Icons.meeting_room_outlined, color: statusColor, size: 32)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.onSurface)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(isOccupied ? 'OCCUPIED' : 'AVAILABLE', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))),
            ])),
          ]),
          const SizedBox(height: 24),
          _buildDetailRow(Icons.category, 'Type', room['type'], scheme),
          _buildDetailRow(Icons.layers, 'Floor', room['floor'], scheme),
          _buildDetailRow(Icons.people, 'Capacity', '${room['capacity']} seats', scheme),
          if (isOccupied) ...[
            _buildDetailRow(Icons.book, 'Subject', room['subject'], scheme),
            _buildDetailRow(Icons.access_time, 'Time', room['time'], scheme),
          ],
          const SizedBox(height: 16),

          // occupancy controls (coloured)
          Row(children: [
            if (!isOccupied)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!mounted) return;
                    setState(() => room['occupied'] = true);
                    Navigator.pop(context);
                    // ---------- UPDATED OCCUPIED SNACKBAR ----------
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Row(
                          children: [
                            const Icon(Icons.door_front_door, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${room['name']} marked OCCUPIED',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.door_front_door),
                  label: const Text('Mark Occupied'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            if (!isOccupied) const SizedBox(width: 12),
            if (isOccupied)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (!mounted) return;
                    setState(() => room['occupied'] = false);
                    Navigator.pop(context);
                    // ---------- UPDATED AVAILABLE SNACKBAR ----------
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${room['name']} marked AVAILABLE',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('Mark Available'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
          ]),
          const SizedBox(height: 16),

          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.check_circle_outline), label: const Text('Got it'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ]),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 12),
        Text('$label: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: scheme.onSurface))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Wrap the entire Scaffold in the same Fade + Slide transition used in ProfilePage.
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Scaffold(
          body: CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.white.withOpacity(0.14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: IconButton(
                          splashRadius: 22,
                          icon: Stack(
                            children: [
                              const Center(child: Icon(Icons.filter_list, color: Colors.white)),
                              if (selectedType != 'All')
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: _showFilterDialog,
                          tooltip: 'Filter',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Classroom Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(blurRadius: 8, color: Colors.black26)])),
                background: Container(
                  // <-- use same header gradient here
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: headerGradientColors(isDark)),
                  ),
                  child: Stack(children: [Positioned(right: -50, top: -50, child: Icon(Icons.meeting_room, size: 180, color: Colors.white.withOpacity(0.1)))]),
                ),
              ),
            ),

            // Stats row (AVAILABLE left, OCCUPIED right)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _buildStatCard(context, 'Available', availableCount.toString(), Icons.meeting_room_outlined, const Color(0xFF10B981))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, 'Occupied', occupiedCount.toString(), Icons.door_front_door, const Color(0xFFEF4444))),
                  ]),
                  const SizedBox(height: 16),
                  // Debounced Search Field (still present in Classrooms area)
                  TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search classrooms...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildFilterChip('All Floors', scheme), _buildFilterChip('1st Floor', scheme), _buildFilterChip('2nd Floor', scheme), _buildFilterChip('3rd Floor', scheme)])),
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12), delegate: SliverChildBuilderDelegate((context, index) {
                final room = filteredClassrooms[index];
                return _buildClassroomCard(context, room);
              }, childCount: filteredClassrooms.length)),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ]),
        ),
      ),
    );
  }
}