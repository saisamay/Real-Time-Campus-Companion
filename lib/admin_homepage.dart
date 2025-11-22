// admin_homepage.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Import necessary external files that were likely removed in the upload snippet
// You'll need to make sure these exist or remove the import if they are placeholders.
// import 'main.dart'; // <--- Removed this line as it causes circular import

class AdminApp extends StatefulWidget {
  const AdminApp({Key? key}) : super(key: key);

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true),
      home: AdminHome(
        isDark: _isDark,
        onThemeChanged: (val) => setState(() => _isDark = val),
      ),
    );
  }
}

class AdminHome extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  const AdminHome({
    Key? key,
    required this.isDark,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  int? _hoveredEventIndex;
  int? _hoveredUserIndex;

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

  String _adminName = 'Admin';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // uploaded image local path from conversation
  final String uploadedImage = 'file:///mnt/data/79635ee1-9b59-441e-a6de-9ff829b6402f.png';

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
          // Header banner - theme toggle removed from here (as you asked)
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
                image: _imageProviderFor(uploadedImage),
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
                      Text('Manage your university dashboard', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    ]),
                  ),
                  // NOTE: Theme icon removed from banner; AppBar still has a toggle button.
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

  Widget _buildTimetable() => const Center(child: Text('Timetable (no content)'));

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
                  TextField(controller: limitCtrl, decoration: const InputDecoration(labelText: 'Registration Limit (number)'), keyboardType: TextInputType.number),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final id = 'e${DateTime.now().millisecondsSinceEpoch}';
                        final limitText = int.tryParse(limitCtrl.text.trim())?.toString() ?? '0';
                        setState(() {
                          _events.add({'id': id, 'title': titleCtrl.text.trim(), 'limit': limitText});
                          _eventRegistrations[id] = <String>{};
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Create')),
                ],
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Event'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _events.isEmpty ? const Center(child: Text('No events yet')) : ListView.builder(
            itemCount: _events.length,
            itemBuilder: (ctx, i) {
              final event = _events[i];
              final regs = _eventRegistrations[event['id']] ?? <String>{};
              final limit = int.tryParse(event['limit'] ?? '0') ?? 0;
              final accent = _paletteColor(i);
              final bg = widget.isDark ? _paletteColor(i, opacity: 0.12) : _paletteColor(i, opacity: 0.14);
              final isHovered = _hoveredEventIndex == i;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredEventIndex = i),
                  onExit: (_) => setState(() => _hoveredEventIndex = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()..scale(isHovered ? 1.01 : 1.0),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(width: 8, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
                      title: Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${regs.length}/${limit > 0 ? limit : "∞"} registrations'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.how_to_reg),
                          onPressed: () {
                            showDialog(context: context, builder: (ctx) => RegistrationDialog(
                              eventId: event['id']!,
                              users: _users,
                              registered: regs,
                              limit: limit,
                              onSave: (newSet) => setState(() => _eventRegistrations[event['id']!] = newSet),
                            ));
                          },
                        ),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () {
                          setState(() {
                            _eventRegistrations.remove(event['id']);
                            _events.removeAt(i);
                          });
                        }),
                      ]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildUsers() {
    final rollCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(children: [
        ElevatedButton.icon(
          onPressed: () {
            rollCtrl.clear();
            showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Add User (Roll Number)'),
              content: TextField(controller: rollCtrl, decoration: const InputDecoration(labelText: 'Roll Number')),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(onPressed: () {
                  final roll = rollCtrl.text.trim();
                  if (roll.isEmpty) return;
                  final id = 'u${DateTime.now().millisecondsSinceEpoch}';
                  setState(() => _users.add({'id': id, 'roll': roll}));
                  Navigator.of(ctx).pop();
                }, child: const Text('Add')),
              ],
            ));
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Add User'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _users.isEmpty ? const Center(child: Text('No users found')) : ListView.builder(
            itemCount: _users.length,
            itemBuilder: (ctx, i) {
              final user = _users[i];
              final roll = user['roll'] ?? '';
              final bg = _paletteColor(i, opacity: widget.isDark ? 0.12 : 0.14);
              final avatarColor = _paletteColor(i);
              final isHovered = _hoveredUserIndex == i;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredUserIndex = i),
                  onExit: (_) => setState(() => _hoveredUserIndex = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()..scale(isHovered ? 1.01 : 1.0),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: avatarColor, child: Text(_avatarFromRoll(roll), style: const TextStyle(color: Colors.white))),
                      title: Text(roll),
                      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () {
                        final id = user['id']!;
                        setState(() {
                          _users.removeAt(i);
                          for (final key in _eventRegistrations.keys) {
                            _eventRegistrations[key]!.remove(id);
                          }
                        });
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // use admin-profile variant you saved previously (profile page file)
  Widget _buildProfile() {
    return AdminProfilePage(
      isDark: widget.isDark,
      onToggleTheme: widget.onThemeChanged,
      initialName: _adminName,
      initialEmail: 'admin@university.edu',
      initialDeptSection: 'Admin',
      initialPhotoUrl: uploadedImage,
      onChangePhoto: _changeProfileImage,
      onChangePassword: (ctx) => _changePassword(ctx), // <-- now matches ValueChanged<BuildContext>
      onLogout: _logout,
      onUpdateName: (n) => setState(() => _adminName = n),
      onUpdateEmail: (e) { /* keep same */ },
      showAdminActions: true,
    );
  }

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
            const CircleAvatar(radius: 28, child: Icon(Icons.admin_panel_settings, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_adminName, style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Administrator', style: TextStyle(color: Colors.white70)),
          ]),
        ),
        item('Courses', Icons.book, () => setState(() => _currentIndex = 0)),
        item('Add User', Icons.person_add, () => setState(() => _currentIndex = 3)),
        item('Edit User', Icons.edit, () => setState(() => _currentIndex = 3)),
        item('Add Timetable', Icons.schedule_send, () => setState(() => _currentIndex = 1)),
        item('Edit Timetable', Icons.edit_calendar, () => setState(() => _currentIndex = 1)),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: InkWell(
            onTap: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out (demo)'))); },
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
        const Expanded(child: Center(child: Text('Your University Name', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)))),
        // Keep AppBar theme toggle available
        IconButton(icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.white), onPressed: () => widget.onThemeChanged(!widget.isDark), tooltip: 'Toggle theme'),
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

      // footer with background, rounded top corners and shadow (kept visible)
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
            BottomNavigationBarItem(icon: CircleAvatar(radius: 15, backgroundColor: _paletteColor(4), child: const Icon(Icons.person, size: 22, color: Colors.white)), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // helper to create ImageProvider for network or local file
  ImageProvider _imageProviderFor(String url) {
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

  // admin helper actions (existing logic kept)
  void _changeProfileImage() {
    // existing admin behavior (kept)
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

/// Registration dialog
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

/// AdminProfilePage
/// This is the profile page you saved as the "admin profile page".
class AdminProfilePage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String initialName;
  final String initialEmail;
  final String initialDeptSection;
  final String initialPhotoUrl;

  // additional callbacks (will be used if provided)
  final VoidCallback? onChangePhoto;
  final ValueChanged<BuildContext>? onChangePassword; // <-- changed to accept BuildContext
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
              // preserve existing logic but call callback if provided
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
            // THEME TOGGLE INSIDE PROFILE
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
              // call the provided handler with the BuildContext so admin logic can show dialogs
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

  // ImageProvider helper reused in profile
  ImageProvider _imageProviderFor(String url) {
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
}