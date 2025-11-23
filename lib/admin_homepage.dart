// lib/admin_homepage.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// --- Imports for your pages ---
import 'api_service.dart';
import 'admin_course_page.dart';
import 'add_user.dart';
import 'edit_user.dart';
import 'add_timetable_page.dart';
import 'edit_timetable_page.dart';

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
  int _currentIndex = 0;
  int? _hoveredEventIndex;
  int? _hoveredUserIndex;

  // Demo Data for Dashboard Widgets
  final List<Map<String, String>> _users = [
    {'id': 'u1', 'roll': 'R001'},
    {'id': 'u2', 'roll': 'R002'},
    {'id': 'u3', 'roll': 'R003'},
  ];

  final List<Map<String, String>> _events = [
    {'id': 'e1', 'title': 'AI Workshop', 'limit': '5'},
    {'id': 'e2', 'title': 'Hackathon', 'limit': '10'},
  ];

  final Map<String, Set<String>> _eventRegistrations = {
    'e1': {'u1'},
    'e2': {},
  };

  late String _adminName;
  late String _profileImage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _adminName = widget.userName;
    _profileImage = widget.profile ?? 'https://via.placeholder.com/150';
  }

  // --- UI Helpers (Colors & Cards) ---
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

  String _avatarFromRoll(String roll) {
    if (roll.isEmpty) return '';
    return roll.length >= 2 ? roll.substring(roll.length - 2) : roll;
  }

  int _totalRegistrations() {
    var sum = 0;
    for (final s in _eventRegistrations.values) sum += s.length;
    return sum;
  }

  // --- Dashboard View ---
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

      Widget summaryRow;
      final cardEvents = SizedBox(
          width: narrow ? 260 : null,
          child: _summaryCard('Events', _events.length.toString(), Icons.event, start: eventsStart, end: eventsEnd));
      final cardRegs = SizedBox(
          width: narrow ? 260 : null,
          child: _summaryCard('Registrations', _totalRegistrations().toString(), Icons.how_to_reg, start: regsStart, end: regsEnd));
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
          // Banner
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

          // Lists (Events & Users)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent events', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Column(
                children: _events.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final regs = _eventRegistrations[e['id']] ?? <String>{};
                  final limit = int.tryParse(e['limit'] ?? '0') ?? 0;
                  final accent = _paletteColor(i);
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
                          leading: Container(width: 8, height: double.infinity, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
                          title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${regs.length}/${limit > 0 ? limit : '∞'} registrations'),
                          trailing: limit > 0 && regs.length >= limit ? const Chip(label: Text('Full'), backgroundColor: Colors.redAccent) : const Icon(Icons.chevron_right),
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

  Widget _buildTimetable() => const Center(child: Text('Timetable Management'));

  Widget _buildEvents() {
    final titleCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(children: [
        ElevatedButton.icon(
          onPressed: () {
            titleCtrl.clear();
            limitCtrl.clear();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Create Event'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title')),
                  const SizedBox(height: 8),
                  TextField(controller: limitCtrl, decoration: const InputDecoration(labelText: 'Limit'), keyboardType: TextInputType.number),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isEmpty) return;
                        setState(() {
                          String id = 'e${DateTime.now().millisecondsSinceEpoch}';
                          _events.add({'id': id, 'title': titleCtrl.text, 'limit': limitCtrl.text});
                          _eventRegistrations[id] = {};
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Create')),
                ],
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Event'),
        ),
        Expanded(child: ListView.builder(itemCount: _events.length, itemBuilder: (c, i) => ListTile(title: Text(_events[i]['title']!))))
      ]),
    );
  }

  Widget _buildUsers() => const Center(child: Text('User Management'));

  Widget _buildProfile() {
    return AdminProfilePage(
      isDark: widget.isDark,
      onToggleTheme: widget.onToggleTheme,
      initialName: _adminName,
      initialEmail: widget.userEmail,
      initialDeptSection: 'Administrator',
      initialPhotoUrl: _profileImage,
      onChangePhoto: _changeProfileImage,
      onChangePassword: (ctx) => _changePassword(ctx),
      onLogout: _logout,
      onUpdateName: (n) => setState(() => _adminName = n),
      onUpdateEmail: (e) { },
      showAdminActions: true,
    );
  }

  // --- DRAWER NAVIGATION ---
  Drawer _buildDrawer() {
    Widget item(String label, IconData icon, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () { Navigator.of(context).pop(); onTap(); },
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
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: _imageProviderFor(_profileImage),
              child: (_profileImage.isEmpty || _profileImage.contains('placeholder'))
                  ? const Icon(Icons.admin_panel_settings, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(_adminName, style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Administrator', style: TextStyle(color: Colors.white70)),
          ]),
        ),

        // 1. Courses Page
        item('Courses', Icons.book, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCoursePage()));
        }),

        // 2. Add User Page
        item('Add User', Icons.person_add, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddUserPage(api: ApiService())));
        }),

        // 3. Edit User Page
        item('Edit User', Icons.edit, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EditUserByEmailPage()));
        }),

        // 4. Add Timetable Page
        item('Add Timetable', Icons.schedule_send, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTimetablePage()));
        }),

        // 5. Edit Timetable Page
        item('Edit Timetable', Icons.edit_calendar, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EditTimetablePage()));
        }),

        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: InkWell(
            onTap: () { Navigator.of(context).pop(); _logout(); },
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
    final pages = [_buildHome(), _buildTimetable(), _buildEvents(), _buildUsers(), _buildProfile()];

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
          currentIndex: (_currentIndex == 0) ? 0 : ((_currentIndex == 2) ? 1 : ((_currentIndex == 4) ? 2 : 0)),
          onTap: (i) {
            setState(() {
              if (i == 0) _currentIndex = 0;
              if (i == 1) _currentIndex = 2;
              if (i == 2) _currentIndex = 4;
            });
          },
          items: [
            BottomNavigationBarItem(icon: CircleAvatar(radius: 15, backgroundColor: _paletteColor(0), child: const Icon(Icons.home, size: 22, color: Colors.white)), label: 'Home'),
            BottomNavigationBarItem(icon: CircleAvatar(radius: 15, backgroundColor: _paletteColor(2), child: const Icon(Icons.event, size: 22, color: Colors.white)), label: 'Events'),
            BottomNavigationBarItem(
                icon: CircleAvatar(
                  radius: 15,
                  backgroundColor: _paletteColor(4),
                  backgroundImage: _imageProviderFor(_profileImage),
                  child: (_profileImage.isEmpty || _profileImage.contains('placeholder'))
                      ? const Icon(Icons.person, size: 22, color: Colors.white)
                      : null,
                ),
                label: 'Profile'
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _imageProviderFor(String url) {
    if (url.isEmpty) return const NetworkImage('https://via.placeholder.com/150');
    if (url.startsWith('file://') && !kIsWeb) {
      try {
        final path = url.replaceFirst('file://', '');
        return FileImage(File(path));
      } catch (_) {
        return const NetworkImage('https://via.placeholder.com/400');
      }
    } else {
      try {
        return NetworkImage(url);
      } catch (_) {
        return const NetworkImage('https://via.placeholder.com/400');
      }
    }
  }

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
    final ok = await showDialog<bool>(context: context, builder: (dCtx) => AlertDialog(title: const Text('Log out?'), content: const Text('Are you sure you want to sign out of this device?'), actions: [TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Log out'))]));
    if (ok == true) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
  }
}

// --- Registration Dialog ---
class RegistrationDialog extends StatefulWidget {
  final String eventId;
  final List<Map<String, String>> users;
  final Set<String> registered;
  final int limit;
  final ValueChanged<Set<String>> onSave;

  const RegistrationDialog({Key? key, required this.eventId, required this.users, required this.registered, required this.limit, required this.onSave}) : super(key: key);

  @override
  State<RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<RegistrationDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.registered);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.limit > 0 ? widget.limit - _selected.length : null;
    return AlertDialog(
      title: Text('Manage Registrations (${widget.eventId})'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.limit > 0)
            Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text('Limit: ${widget.limit} — Selected: ${_selected.length} — Remaining: ${remaining! >= 0 ? remaining : 0}'))
          else
            const Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text('No registration limit (∞)')),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.users.length,
              itemBuilder: (ctx, i) {
                final u = widget.users[i];
                final uid = u['id']!;
                final roll = u['roll'] ?? '';
                final checked = _selected.contains(uid);
                return CheckboxListTile(
                  value: checked,
                  title: Text(roll),
                  onChanged: (val) {
                    if (val == true) {
                      if (widget.limit > 0 && _selected.length >= widget.limit) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration limit reached')));
                        return;
                      }
                      setState(() => _selected.add(uid));
                    } else {
                      setState(() => _selected.remove(uid));
                    }
                  },
                );
              },
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          widget.onSave(_selected);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrations updated (demo)')));
        }, child: const Text('Save')),
      ],
    );
  }
}

// --- Admin Profile Page Class ---
class AdminProfilePage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String initialName;
  final String initialEmail;
  final String initialDeptSection;
  final String initialPhotoUrl;
  final VoidCallback? onChangePhoto;
  final ValueChanged<BuildContext>? onChangePassword;
  final VoidCallback? onLogout;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateEmail;
  final bool showAdminActions;

  const AdminProfilePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.initialName = 'John Doe',
    this.initialEmail = 'student@university.edu',
    this.initialDeptSection = 'CSE-B',
    this.initialPhotoUrl = 'https://images.unsplash.com/photo-1523580846011-d3a5bc25702b?auto=format&fit=crop&w=800&q=80',
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

class _AdminProfilePageState extends State<AdminProfilePage> {
  late String userName = widget.initialName;
  late String userEmail = widget.initialEmail;
  late String userDeptSection = widget.initialDeptSection;
  late String profileImage = widget.initialPhotoUrl;
  late bool _localIsDark = widget.isDark;

  @override
  void didUpdateWidget(covariant AdminProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) _localIsDark = widget.isDark;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Container(
        height: 180,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _imageProviderFor(profileImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.35), BlendMode.darken),
          ),
        ),
        child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CircleAvatar(radius: 36, backgroundImage: _imageProviderFor(profileImage)),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(userName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            Text('$userDeptSection • $userEmail', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(.9))),
          ])),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (widget.onChangePhoto != null) widget.onChangePhoto!();
              setState(() { profileImage = 'https://images.unsplash.com/photo-1525973132219-a04334a76080?auto=format&fit=crop&w=800&q=80'; });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.lightBlueAccent, side: const BorderSide(color: Colors.lightBlueAccent)),
            child: const Text('Change Photo'),
          ),
        ]))),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: [
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(children: [
            _settingTile(icon: Icons.badge, title: 'Name', subtitle: userName, onTap: () => _editTextField(context, title: 'Edit Name', initial: userName, onSave: (v) {
              setState(() => userName = v);
              widget.onUpdateName?.call(v);
            })),
            _divider(),
            _settingTile(icon: Icons.apartment, title: 'Department', subtitle: userDeptSection, onTap: () => _editTextField(context, title: 'Edit Department & Section', hint: 'e.g., CSE-B', initial: userDeptSection, onSave: (v) => setState(() => userDeptSection = v))),
            _divider(),
            _settingTile(icon: Icons.email, title: 'Email', subtitle: userEmail, onTap: () => _editTextField(context, title: 'Edit Email', initial: userEmail, keyboardType: TextInputType.emailAddress, onSave: (v) { setState(() => userEmail = v); widget.onUpdateEmail?.call(v); })),
            _divider(),
            SwitchListTile(
              secondary: const Icon(Icons.brightness_6),
              title: const Text('Dark Mode'),
              value: _localIsDark,
              onChanged: (val) {
                setState(() => _localIsDark = val);
                widget.onToggleTheme(val);
              },
            ),
          ])),
          const SizedBox(height: 12),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(children: [
            _settingTile(icon: Icons.lock, title: 'Change Password', subtitle: 'Update your password', onTap: () {
              widget.onChangePassword?.call(context);
              _changePassword(context);
            }),
            _divider(),
            _settingTile(icon: Icons.logout, title: 'Log out', subtitle: 'Sign out of this device', onTap: () {
              widget.onLogout?.call();
              _logout();
            }),
          ])),
        ]),
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _settingTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: subtitle == null ? null : Text(subtitle), trailing: onTap == null ? null : const Icon(Icons.chevron_right), onTap: onTap);
  }

  Widget _divider() => const Divider(height: 0, indent: 16, endIndent: 16);

  Future<void> _editTextField(BuildContext ctx, {required String title, required String initial, String? hint, TextInputType? keyboardType, required ValueChanged<String> onSave}) async {
    final controller = TextEditingController(text: initial);
    await showDialog(context: ctx, builder: (dCtx) => AlertDialog(title: Text(title), content: TextField(controller: controller, decoration: InputDecoration(hintText: hint), keyboardType: keyboardType, autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')), ElevatedButton(onPressed: () { onSave(controller.text.trim()); Navigator.pop(dCtx); }, child: const Text('Save'))]));
  }

  Future<void> _changePassword(BuildContext ctx) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog(context: ctx, builder: (dCtx) => AlertDialog(title: const Text('Change Password'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')), const SizedBox(height: 8), TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')), const SizedBox(height: 8), TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password'))]), actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')), ElevatedButton(onPressed: () { if (newCtrl.text != confirmCtrl.text || newCtrl.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Passwords do not match'))); return; } Navigator.pop(dCtx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password changed'))); }, child: const Text('Update'))]));
  }

  void _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (dCtx) => AlertDialog(title: const Text('Log out?'), content: const Text('Are you sure you want to sign out of this device?'), actions: [TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Log out'))]));
    if (ok == true) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
  }

  ImageProvider _imageProviderFor(String url) {
    if (url.isEmpty) return const NetworkImage('https://via.placeholder.com/150');
    if (url.startsWith('file://') && !kIsWeb) {
      try {
        final path = url.replaceFirst('file://', '');
        return FileImage(File(path));
      } catch (_) {
        return const NetworkImage('https://via.placeholder.com/400');
      }
    } else {
      try {
        return NetworkImage(url);
      } catch (_) {
        return const NetworkImage('https://via.placeholder.com/400');
      }
    }
  }
}