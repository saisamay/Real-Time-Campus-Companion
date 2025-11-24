// lib/admin_homepage.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// --- External Page Imports ---
import 'api_service.dart';
import 'event_handler.dart';
import 'admin_course_page.dart';
import 'add_user.dart';
import 'edit_user.dart';
import 'add_timetable_page.dart';
import 'edit_timetable_page.dart';
import 'faculty_cabin_page.dart';   // Ensure you have the file from the previous step
import 'main.dart';                 // For LoginPage redirection

class AdminHomePage extends StatefulWidget {
  final String universityName;
  final String userName;
  final String userEmail;
  final String? profile;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const AdminHomePage({
    Key? key,
    required this.universityName,
    required this.userName,
    required this.userEmail,
    this.profile,
    required this.isDark,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // 0 = Home, 1 = Events, 2 = Profile
  int _currentIndex = 0;

  // Hover states for dashboard cards
  int? _hoveredEventIndex;
  int? _hoveredUserIndex;

  // --- Backend Data State ---
  List<dynamic> _dashboardEvents = [];
  bool _isLoading = true;

  // Mock Users for Dashboard Display
  final List<Map<String, String>> _users = [
    {'id': 'u1', 'roll': 'R001'},
    {'id': 'u2', 'roll': 'R002'},
    {'id': 'u3', 'roll': 'R003'},
  ];

  late String _adminName;
  late String _profileImage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initialize with data passed from main.dart
    _adminName = widget.userName;
    _profileImage = widget.profile ?? '';
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final events = await ApiService.getAllEvents();
      if (mounted) {
        setState(() {
          _dashboardEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading dashboard data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Color Palettes ---
  List<Color> get _palette => [
    const Color(0xFF0D6EFD),
    const Color(0xFF20C997),
    const Color(0xFFFFA927),
    const Color(0xFF8A63D2),
    const Color(0xFFEF476F),
  ];

  Color _paletteColor(int index, {double opacity = 1.0}) {
    final base = _palette[index % _palette.length];
    return base.withOpacity(opacity);
  }

  // --- Helpers ---
  String _avatarFromRoll(String roll) {
    if (roll.isEmpty) return '';
    return roll.length >= 2 ? roll.substring(roll.length - 2) : roll;
  }

  ImageProvider _imageProviderFor(String url) {
    if (url.isEmpty) return const NetworkImage('https://via.placeholder.com/400');

    if (url.startsWith('file://') && !kIsWeb) {
      try {
        final path = url.replaceFirst('file://', '');
        return FileImage(File(path));
      } catch (_) {
        return const NetworkImage('https://via.placeholder.com/400');
      }
    } else {
      return NetworkImage(url);
    }
  }

  // --- Main Dashboard Views ---

  Widget _summaryCard(String title, String value, IconData icon, {required Color start, required Color end}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: end.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.18),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        ]),
      ]),
    );
  }

  Widget _buildHome() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final narrow = width < 700;

      final eventsStart = const Color(0xFF0B57D0);
      final eventsEnd = const Color(0xFF0646A6);
      final regsStart = const Color(0xFF27E08D);
      final regsEnd = const Color(0xFF118B4A);
      final usersStart = const Color(0xFFFFB300);
      final usersEnd = const Color(0xFFEF6C00);

      final eventCount = _dashboardEvents.length.toString();

      Widget summaryRow;
      final cardEvents = SizedBox(
          width: narrow ? 260 : null,
          child: _summaryCard('Events', eventCount, Icons.event, start: eventsStart, end: eventsEnd));
      final cardRegs = SizedBox(
          width: narrow ? 260 : null,
          child: _summaryCard('Registrations', 'N/A', Icons.how_to_reg, start: regsStart, end: regsEnd));
      final cardUsers = SizedBox(
          width: narrow ? 260 : null,
          child: _summaryCard('Users', _users.length.toString(), Icons.people, start: usersStart, end: usersEnd));

      if (!narrow) {
        summaryRow = Row(
          children: [
            Expanded(child: cardEvents),
            const SizedBox(width: 12),
            Expanded(child: cardRegs),
            const SizedBox(width: 12),
            Expanded(child: cardUsers),
          ],
        );
      } else {
        summaryRow = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [cardEvents, const SizedBox(width: 12), cardRegs, const SizedBox(width: 12), cardUsers]),
        );
      }

      return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // --- HEADER / BANNER ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            height: narrow ? 140 : 160,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              gradient: LinearGradient(
                colors: widget.isDark ? [Colors.grey.shade900, Colors.grey.shade800] : const [Color(0xFF0D6EFD), Color(0xFF20C997)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              image: DecorationImage(
                image: _imageProviderFor(_profileImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.06), BlendMode.darken),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundColor: Colors.white.withOpacity(0.12), child: const Icon(Icons.admin_panel_settings, size: 26, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome,', style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(_adminName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(widget.universityName, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // --- SUMMARY CARDS ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF7FBFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.02) : Colors.blue.withOpacity(0.04)),
              ),
              child: summaryRow,
            ),
          ),

          const SizedBox(height: 18),

          // --- RECENT EVENTS & USERS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent events', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_dashboardEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("No events found."),
                )
              else
                Column(
                  children: _dashboardEvents.take(5).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final event = entry.value;

                    final String title = event['title'] ?? 'Untitled';
                    final String imageUrl = event['imageUrl'] ?? '';
                    final String date = event['date'] != null
                        ? event['date'].toString().substring(0, 10)
                        : '';

                    final bg = widget.isDark ? _paletteColor(i, opacity: 0.12) : _paletteColor(i, opacity: 0.10);
                    final isHovered = _hoveredEventIndex == i;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredEventIndex = i),
                        onExit: (_) => setState(() => _hoveredEventIndex = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => Container(
                                  width: 50, height: 50,
                                  color: _paletteColor(i),
                                  child: const Icon(Icons.event, color: Colors.white),
                                ),
                              )
                                  : Container(
                                width: 50, height: 50,
                                color: _paletteColor(i),
                                child: const Icon(Icons.event, color: Colors.white),
                              ),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(date),
                            trailing: const Icon(Icons.chevron_right),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 18),
              Text('Recent users', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Column(
                children: _users.take(8).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final u = entry.value;
                  final roll = u['roll'] ?? '';
                  final bg = _paletteColor(i, opacity: widget.isDark ? 0.12 : 0.08);
                  final avatarColor = _paletteColor(i);
                  final isHovered = _hoveredUserIndex == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveredUserIndex = i),
                      onExit: (_) => setState(() => _hoveredUserIndex = null),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        scale: isHovered ? 1.02 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: avatarColor, child: Text(_avatarFromRoll(roll), style: const TextStyle(color: Colors.white))),
                            title: Text(roll),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _buildProfile() {
    return AdminProfilePage(
      initialName: _adminName,
      initialEmail: widget.userEmail,
      initialDeptSection: 'Admin',
      initialPhotoUrl: _profileImage,
      onChangePhoto: _changeProfileImage,
      onChangePassword: (ctx) => _changePassword(ctx),
      onLogout: _logout,
      onToggleTheme: widget.onToggleTheme,
      onUpdateName: (n) => setState(() => _adminName = n),
      onUpdateEmail: (e) { /* keep same */ },
      showAdminActions: true,
      isDark: widget.isDark,
    );
  }

  // --- DRAWER WITH CONNECTED PAGES ---
  Drawer _buildDrawer() {
    // Helper for Drawer Items
    Widget item(String label, IconData icon, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () { Navigator.of(context).pop(); onTap(); }, // Close drawer then navigate
        child: ListTile(
          leading: Container(width: 6, height: double.infinity, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(6))),
          title: Text(label, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          trailing: Icon(icon, color: widget.isDark ? Colors.white : Colors.blue),
        ),
      ),
    );

    return Drawer(
      backgroundColor: widget.isDark ? Colors.grey.shade900 : Colors.white,
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.isDark ? [Colors.grey.shade900, Colors.grey.shade800] : const [Color(0xFF0D6EFD), Color(0xFF20C997)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.admin_panel_settings, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_adminName, style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Administrator', style: TextStyle(color: Colors.white70)),
          ]),
        ),

        // --- NAVIGATION LINKS ---

        // 1. Courses (Navigate to External Page)
        item('Courses', Icons.book, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCoursePage()));
        }),

        // 2. Add User (Navigate to External Page)
        item('Add User', Icons.person_add, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddUserPage(api: ApiService())));
        }),

        // 3. Edit User (Navigate to External Page)
        item('Edit User', Icons.edit, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EditUserPage()));
        }),

        // 4. Add Timetable (Navigate to External Page)
        item('Add Timetable', Icons.schedule_send, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTimetablePage()));
        }),

        // 5. Edit Timetable (Navigate to External Page)
        item('Edit Timetable', Icons.edit_calendar, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EditTimetablePage()));
        }),

        // 6. Faculty Cabin (Navigate to NEW Separate Page)
        item('Faculty Cabin', Icons.meeting_room, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FacultyCabinPage()));
        }),

        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              _logout();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(color: widget.isDark ? Colors.red.withOpacity(.08) : Colors.red.withOpacity(.06), borderRadius: BorderRadius.circular(10)),
              child: ListTile(leading: Container(width: 6, height: double.infinity, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6))), title: Text('Logout', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)), trailing: Icon(Icons.logout, color: widget.isDark ? Colors.white : Colors.redAccent)),
            ),
          ),
        ),
      ]),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: widget.isDark ? [Colors.grey.shade900, Colors.grey.shade800] : const [Color(0xFF0D6EFD), Color(0xFF20C997)], begin: Alignment.centerLeft, end: Alignment.centerRight))),
      title: Row(children: [
        IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        const SizedBox(width: 8),
        Expanded(child: Center(child: Text(widget.universityName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)))),
        IconButton(icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.white), onPressed: () => widget.onToggleTheme(!widget.isDark), tooltip: 'Toggle theme'),
      ]),
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // We only keep the Main Tabs here. All management tools (User/Timetable/Faculty) are now in the Drawer.
    final pages = [
      _buildHome(),             // 0: Home Dashboard
      const EventHandlerPage(), // 1: Full Event Page (Connected)
      _buildProfile(),          // 2: Profile Page
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(key: ValueKey(_currentIndex), height: double.infinity, child: pages[_currentIndex]),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey.shade900.withOpacity(0.92) : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() {
              _currentIndex = i;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home, size: 26), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.event, size: 26), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.person, size: 26), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // --- Actions & Dialogs ---

  void _changeProfileImage() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated (admin handler)')));
  }

  Future<void> _changePassword(BuildContext ctx) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog(context: ctx, builder: (dCtx) => AlertDialog(title: const Text('Change Password'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')), const SizedBox(height: 8), TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')), const SizedBox(height: 8), TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password'))]), actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')), ElevatedButton(onPressed: () { if (newCtrl.text != confirmCtrl.text || newCtrl.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Passwords do not match'))); return; } Navigator.pop(dCtx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password changed'))); }, child: const Text('Update'))]));
  }

  void _logout() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: const Text('Cancel')
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: const Text('Log out')
              )
            ]
        )
    );

    if (ok == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => LoginPage(
                onToggleTheme: (val) {},
                isDark: widget.isDark
            )
        ),
            (route) => false,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// AdminProfilePage
// ---------------------------------------------------------------------------
List<Color> headerGradientColors(bool isDark) {
  return isDark ? [const Color(0xFF2D2D2D), const Color(0xFF0B0B0B)] : [const Color(0xFF06B6D4), const Color(0xFF06D6A0)];
}

class AdminProfilePage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final String initialName;
  final String initialEmail;
  final String initialDeptSection;
  final String? initialPhotoUrl;
  final VoidCallback? onChangePhoto;
  final ValueChanged<BuildContext>? onChangePassword;
  final VoidCallback? onLogout;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateEmail;
  final bool showAdminActions;

  const AdminProfilePage({
    super.key,
    this.isDark = false,
    this.onToggleTheme,
    this.initialName = 'John Doe',
    this.initialEmail = 'student@university.edu',
    this.initialDeptSection = 'CSE-B',
    this.initialPhotoUrl,
    this.onChangePhoto,
    this.onChangePassword,
    this.onLogout,
    this.onUpdateName,
    this.onUpdateEmail,
    this.showAdminActions = false,
  });

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> with SingleTickerProviderStateMixin {
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
    _name = widget.initialName;
    _email = widget.initialEmail;
    _localIsDark = widget.isDark;
    _profileImage = widget.initialPhotoUrl ?? "https://i.pravatar.cc/150?img=3";

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AdminProfilePage oldWidget) {
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
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.edit, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), const Text('Edit Name')]),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.person))),
        actions: [TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Save'))],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _name = ctrl.text.trim());
      widget.onUpdateName?.call(_name);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('Name updated successfully')]), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Future<void> _editEmail() async {
    final ctrl = TextEditingController(text: _email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.email, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), const Text('Edit Email')]),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
        actions: [TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Save'))],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _email = ctrl.text.trim());
      widget.onUpdateEmail?.call(_email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('Email updated successfully')]), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  ImageProvider _imageProvider(String url) {
    if ((url.startsWith('file://') || File(url).existsSync()) && !kIsWeb) {
      try {
        final cleaned = url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
        return FileImage(File(cleaned));
      } catch (_) {
        return const NetworkImage('https://via.placeholder.com/400');
      }
    } else {
      return NetworkImage(url);
    }
  }

  Widget _buildActionCard({required BuildContext context, required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color? iconColor}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.outlineVariant.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: (iconColor ?? cs.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: iconColor ?? cs.primary, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))])), Icon(Icons.chevron_right, color: cs.onSurfaceVariant)]),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.outlineVariant.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(_localIsDark ? Icons.dark_mode : Icons.light_mode, color: cs.primary, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)), const SizedBox(height: 2), Text(_localIsDark ? 'Dark mode enabled' : 'Light mode enabled', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))])), Switch.adaptive(value: _localIsDark, onChanged: (value) { setState(() => _localIsDark = value); widget.onToggleTheme?.call(value); })]),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: headerGradientColors(isDark)), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: (isDark ? headerGradientColors(isDark).first : const Color(0xFF00ACC1)).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(children: [Row(children: [Stack(children: [Hero(tag: 'profile_image', child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]), child: CircleAvatar(radius: 45, backgroundImage: _imageProvider(_profileImage))))]), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.school, color: Colors.white, size: 16), const SizedBox(width: 6), Text(widget.initialDeptSection, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))]))]))]), const SizedBox(height: 16), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.email, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(_email, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))]))]),
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
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [_buildActionCard(context: context, icon: Icons.person, title: 'Edit Name', subtitle: 'Update your display name', onTap: _editName), const SizedBox(height: 12), _buildActionCard(context: context, icon: Icons.email, title: 'Edit Email', subtitle: 'Change your email address', onTap: _editEmail), const SizedBox(height: 12), _buildThemeCard(context), if (widget.showAdminActions) ...[const SizedBox(height: 12), _buildActionCard(context: context, icon: Icons.lock, title: 'Change Password', subtitle: 'Update your password', onTap: () => widget.onChangePassword?.call(context)), const SizedBox(height: 12), _buildActionCard(context: context, icon: Icons.logout, title: 'Log Out', subtitle: 'Sign out of your account', onTap: () => widget.onLogout?.call(), iconColor: Theme.of(context).colorScheme.error)]])),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}