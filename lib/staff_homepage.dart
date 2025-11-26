import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'main.dart'; // Required for LoginPage navigation
import 'emptyclassrooms_page.dart'; // ✅ Import the shared page
import 'api_service.dart'; // Required if used directly, though mostly used in sub-pages

// Helper: header/profile gradient colors
List<Color> headerGradientColors(bool isDark) {
  return isDark
      ? [const Color(0xFF2D2D2D), const Color(0xFF0B0B0B)]
      : [const Color(0xFF06B6D4), const Color(0xFF06D6A0)];
}

class StaffHomePage extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String userName;
  final String userEmail;
  final String? profile;

  const StaffHomePage({
    super.key,
    required this.universityName,
    required this.isDark,
    required this.onToggleTheme,
    required this.userName,
    required this.userEmail,
    required this.profile,
  });

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _index = 0;
  late PageController _pageController;

  // Profile info
  late String staffName;
  late String staffEmail;
  String department = 'Administration';
  String office = 'Block B - 102';

  // Simple in-memory password (for demo)
  String _password = 'password123';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    staffName = widget.userName;
    staffEmail = widget.userEmail;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() {
      _index = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _showChangePasswordDialog(BuildContext ctx) async {
    final cur = TextEditingController();
    final nw = TextEditingController();
    final conf = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: cur,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Enter current password';
                if (v != _password) return 'Current password incorrect';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if ((v ?? '').length < 6) return 'Min 6 chars';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: conf,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v != nw.text) return 'Passwords do not match';
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                setState(() => _password = nw.text);
                Navigator.pop(dCtx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: const Text('Password changed'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.universityName),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              tooltip: widget.isDark ? 'Switch to light' : 'Switch to dark',
              icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => widget.onToggleTheme(!widget.isDark),
            ),
          ),
        ],
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerGradientColors(widget.isDark),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=11"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    staffName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    staffEmail,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _goToPage(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _goToPage(1);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      isDark: widget.isDark,
                      onToggleTheme: widget.onToggleTheme,
                    ),
                  ),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          // ✅ FIXED: Use the shared EmptyClassroomsPage with Staff context
          EmptyClassroomsPage(
            userBranch: staffName, // Shows "Occupied by [Staff Name]"
            userSection: 'Staff',
          ),

          // Reuse ProfilePage but configured for Staff
          ProfilePage(
            userName: staffName,
            userEmail: staffEmail,
            dept: department,
            section: office,
            isDark: widget.isDark,
            initialPhotoUrl: "https://i.pravatar.cc/150?img=11",
            onToggleTheme: (v) => widget.onToggleTheme(v),
            onUpdateName: (newName) => setState(() => staffName = newName),
            onUpdateEmail: (newEmail) => setState(() => staffEmail = newEmail),
            onChangePassword: () => _showChangePasswordDialog(context),
            onLogout: () {
              showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dCtx);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => LoginPage(
                              isDark: widget.isDark,
                              onToggleTheme: widget.onToggleTheme,
                            ),
                          ),
                              (route) => false,
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
            },
            showAdminActions: true,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goToPage,
          elevation: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Classrooms'), // Changed Icon/Label
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ------------------ PROFILE PAGE ------------------
class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String dept;
  final String section;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateEmail;
  final String? initialPhotoUrl;
  final VoidCallback? onChangePhoto;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;
  final bool showAdminActions;

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
  late bool _localIsDark;
  late String _profileImage;
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

  Widget _buildInfoCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: CircleAvatar(radius: 45, backgroundImage: NetworkImage(_profileImage)),
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
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
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
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
                          const Icon(Icons.work, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${widget.dept} - ${widget.section}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
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
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(_localIsDark ? 'Dark mode enabled' : 'Light mode enabled', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
              child: Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildActionCard(context: context, icon: Icons.person, title: 'Edit Name', subtitle: 'Update your display name', onTap: _editName),
                  const SizedBox(height: 12),
                  _buildActionCard(context: context, icon: Icons.email, title: 'Edit Email', subtitle: 'Change your email address', onTap: _editEmail),
                  const SizedBox(height: 12),
                  _buildThemeCard(context),
                  if (widget.showAdminActions) ...[
                    const SizedBox(height: 12),
                    _buildActionCard(context: context, icon: Icons.lock, title: 'Change Password', subtitle: 'Update your password', onTap: widget.onChangePassword!),
                    const SizedBox(height: 12),
                    _buildActionCard(context: context, icon: Icons.logout, title: 'Log Out', subtitle: 'Sign out of your account', onTap: widget.onLogout!, iconColor: Theme.of(context).colorScheme.error),
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