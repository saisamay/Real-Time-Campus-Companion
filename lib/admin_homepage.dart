// lib/admin_homepage.dart
import 'package:flutter/material.dart';
import 'main.dart'; // for LoginPage navigation

/// AdminHomePage is a thin wrapper used by the app to navigate to the admin UI.
/// Do NOT create another MaterialApp here — your main app already has one.
/// Pass the theme toggle callback from the app root so AdminHome can change theme.
class AdminHomePage extends StatelessWidget {
  final String universityName;
  final String userName;
  final String userEmail;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const AdminHomePage({
    super.key,
    required this.universityName,
    required this.userName,
    required this.userEmail,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Forward props to the actual stateful AdminHome widget.
    return AdminHome(
      isDark: isDark,
      onToggleTheme: onToggleTheme,
    );
  }
}

class AdminHome extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const AdminHome({
    Key? key,
    required this.isDark,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  // hover trackers
  int? _hoveredEventIndex;
  int? _hoveredUserIndex;
  int? _hoveredDrawerIndex;

  // Users using roll numbers
  final List<Map<String, String>> _users = [
    {'id': 'u1', 'roll': 'R001'},
    {'id': 'u2', 'roll': 'R002'},
  ];

  // Events include registration limit
  final List<Map<String, String>> _events = [
    {'id': 'e1', 'title': 'AI Workshop', 'limit': '5'},
    {'id': 'e2', 'title': 'Hackathon', 'limit': '10'},
  ];

  // eventId -> set of user ids who registered
  final Map<String, Set<String>> _eventRegistrations = {
    'e1': {'u1'},
    'e2': {},
  };

  String _adminName = 'Admin';
  String _adminEmail = 'admin@university.edu';
  String _adminDeptSection = 'Admin';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Color palette used for events/users — cycles when more items exist
  List<Color> get _palette => [
    const Color(0xFF0D6EFD), // blue
    const Color(0xFF20C997), // teal
    const Color(0xFFFFA927), // orange
    const Color(0xFF8A63D2), // purple
    const Color(0xFFEF476F), // pink/red
  ];

  Color _paletteColor(int index, {double opacity = 1.0}) {
    final base = _palette[index % _palette.length];
    return base.withOpacity(opacity);
  }

  // --- Helpers ---
  Widget _adaptiveSummaryCards(BoxConstraints c) {
    // Use grid if wide enough
    final isWide = c.maxWidth > 700;
    final children = [
      _summaryCard('Events', _events.length.toString(), Icons.event),
      _summaryCard('Users', _users.length.toString(), Icons.people),
      _summaryCard('Registrations', _totalRegistrations().toString(), Icons.how_to_reg),
    ];
    return isWide
        ? Row(
      children: children
          .map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: w)))
          .toList(growable: false),
    )
        : Column(
      children: children
          .map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w))
          .toList(growable: false),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 12),
          Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              ])),
        ],
      ),
    );
  }

  String _avatarFromRoll(String roll) {
    if (roll.isEmpty) return '';
    return roll.length >= 2 ? roll.substring(roll.length - 2) : roll;
  }

  int _totalRegistrations() {
    var sum = 0;
    for (final v in _eventRegistrations.values) sum += v.length;
    return sum;
  }

  // --- Pages (with hover & responsive tweaks) ---

  Widget _buildHome() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final quickButtonStyle = ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14));
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero welcome banner
            Container(
              height: width < 500 ? 300 : 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isDark ? [Colors.grey.shade900, Colors.grey.shade800] : const [Color(0xFF0D6EFD), Color(0xFF20C997)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: SafeArea(
                bottom: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  Row(children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.admin_panel_settings, size: 30)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Welcome,', style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: width < 360 ? 16 : 18)),
                        const SizedBox(height: 4),
                        Text(_adminName, style: TextStyle(color: Colors.white, fontSize: width < 360 ? 28 : 34, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis, maxLines: 1),
                        const SizedBox(height: 6),
                        Text('Manage your university dashboard', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Quick actions — wrap on small screens
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    SizedBox(
                      width: width < 520 ? width : (width - 56) / 2,
                      child: ElevatedButton.icon(onPressed: () => setState(() => _currentIndex = 2), icon: const Icon(Icons.event), label: const Text('Create Event'), style: quickButtonStyle),
                    ),
                    SizedBox(
                      width: width < 520 ? width : (width - 56) / 2,
                      child: OutlinedButton.icon(onPressed: () => setState(() => _currentIndex = 3), icon: const Icon(Icons.person_add), label: const Text('Add User'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14))),
                    ),
                  ])
                ]),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Summary (responsive)
                LayoutBuilder(builder: (c2, cons) => _adaptiveSummaryCards(cons)),
                const SizedBox(height: 18),
                Text('Recent events', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                // colorized event rows with hover
                Column(
                  children: _events.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final regs = _eventRegistrations[e['id']] ?? <String>{};
                    final limit = int.tryParse(e['limit'] ?? '0') ?? 0;
                    final atCapacity = limit > 0 && regs.length >= limit;
                    final accent = _paletteColor(i, opacity: 1.0);
                    final bg = widget.isDark ? _paletteColor(i, opacity: 0.12) : _paletteColor(i, opacity: 0.10);
                    final isHovered = _hoveredEventIndex == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredEventIndex = i),
                        onExit: (_) => setState(() => _hoveredEventIndex = null),
                        child: GestureDetector(
                          onTap: () => setState(() => _currentIndex = 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), boxShadow: [
                              if (isHovered) BoxShadow(color: accent.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6))
                            ]),
                            child: ListTile(
                              leading: Container(width: 8, height: double.infinity, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
                              title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${regs.length}/${limit > 0 ? limit : '∞'} registrations'),
                              trailing: atCapacity ? const Chip(label: Text('Full'), backgroundColor: Colors.redAccent) : const Icon(Icons.chevron_right),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
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
                  children: _users.take(4).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final u = entry.value;
                    final roll = u['roll'] ?? '';
                    final bg = _paletteColor(i, opacity: widget.isDark ? 0.12 : 0.08);
                    final avatarColor = _paletteColor(i, opacity: 1.0);
                    final isHovered = _hoveredUserIndex == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredUserIndex = i),
                        onExit: (_) => setState(() => _hoveredUserIndex = null),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isHovered ? 1.02 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), boxShadow: [
                              if (isHovered) BoxShadow(color: avatarColor.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 6))
                            ]),
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
          ],
        ),
      );
    });
  }

  Widget _buildTimetable() {
    return const Center(child: Text('Timetable (no content)'));
  }

  Widget _buildEvents() {
    final titleController = TextEditingController();
    final limitController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(children: [
        ElevatedButton.icon(
          onPressed: () {
            titleController.clear();
            limitController.clear();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Create Event'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Event Title')),
                  const SizedBox(height: 8),
                  TextField(controller: limitController, decoration: const InputDecoration(labelText: 'Registration Limit (number)'), keyboardType: TextInputType.number),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        final id = 'e${DateTime.now().millisecondsSinceEpoch}';
                        final limitText = int.tryParse(limitController.text.trim())?.toString() ?? '0';
                        setState(() {
                          _events.add({'id': id, 'title': titleController.text.trim(), 'limit': limitText});
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
          child: _events.isEmpty
              ? const Center(child: Text('No events yet'))
              : ListView.builder(
            itemCount: _events.length,
            itemBuilder: (ctx, i) {
              final event = _events[i];
              final regs = _eventRegistrations[event['id']] ?? <String>{};
              final limit = int.tryParse(event['limit'] ?? '0') ?? 0;
              final accent = _paletteColor(i, opacity: 1.0);
              final bg = widget.isDark ? _paletteColor(i, opacity: 0.12) : _paletteColor(i, opacity: 0.14);
              final isHovered = _hoveredEventIndex == i;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredEventIndex = i),
                  onExit: (_) => setState(() => _hoveredEventIndex = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    transform: Matrix4.identity()..scale(isHovered ? 1.01 : 1.0),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), boxShadow: [
                      if (isHovered) BoxShadow(color: accent.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 6))
                    ]),
                    child: ListTile(
                      leading: Container(width: 8, height: double.infinity, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
                      title: Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${regs.length}/${limit > 0 ? limit : "∞"} registrations'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.how_to_reg),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => RegistrationDialog(
                                eventId: event['id']!,
                                users: _users,
                                registered: regs,
                                limit: limit,
                                onSave: (newSet) {
                                  setState(() {
                                    _eventRegistrations[event['id']!] = newSet;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _eventRegistrations.remove(event['id']);
                              _events.removeAt(i);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event removed')));
                          },
                        ),
                      ]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ]),
    );
  }

  Widget _buildUsers() {
    final rollController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(children: [
        ElevatedButton.icon(
          onPressed: () {
            rollController.clear();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Add User (Roll Number)'),
                content: TextField(controller: rollController, decoration: const InputDecoration(labelText: 'Roll Number')),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        final roll = rollController.text.trim();
                        if (roll.isEmpty) return;
                        final id = 'u${DateTime.now().millisecondsSinceEpoch}';
                        setState(() {
                          _users.add({'id': id, 'roll': roll});
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Add')),
                ],
              ),
            );
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Add User'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
            itemCount: _users.length,
            itemBuilder: (ctx, i) {
              final user = _users[i];
              final roll = user['roll'] ?? '';
              final bg = _paletteColor(i, opacity: widget.isDark ? 0.12 : 0.14);
              final avatarColor = _paletteColor(i, opacity: 1.0);
              final isHovered = _hoveredUserIndex == i;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredUserIndex = i),
                  onExit: (_) => setState(() => _hoveredUserIndex = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    transform: Matrix4.identity()..scale(isHovered ? 1.01 : 1.0),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), boxShadow: [
                      if (isHovered) BoxShadow(color: avatarColor.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 6))
                    ]),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: avatarColor, child: Text(_avatarFromRoll(roll), style: const TextStyle(color: Colors.white))),
                      title: Text(roll),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          final userId = user['id']!;
                          setState(() {
                            _users.removeAt(i);
                            for (final key in _eventRegistrations.keys) {
                              _eventRegistrations[key]!.remove(userId);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User removed')));
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ]),
    );
  }

  // Build profile: capture widget.onToggleTheme explicitly
  Widget _buildProfile() {
    final ValueChanged<bool> onToggle = widget.onToggleTheme;
    final bool isDark = widget.isDark;

    return ProfilePage(
      isDark: isDark,
      onToggleTheme: onToggle,
      initialName: _adminName,
      initialEmail: _adminEmail,
      initialDeptSection: _adminDeptSection,
    );
  }

  // Drawer with hover & close-on-select
  Drawer _buildDrawer() {
    Widget _menuItem({required int index, required IconData icon, required String label, required VoidCallback onTap}) {
      final color = _paletteColor(index);
      final tileBg = _currentIndex == index ? _paletteColor(index, opacity: widget.isDark ? 0.18 : 0.12) : Colors.transparent;
      final iconColor = widget.isDark ? Colors.white : color;
      final textColor = widget.isDark ? Colors.white : Colors.black87;
      final isHovered = _hoveredDrawerIndex == index;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredDrawerIndex = index),
          onExit: (_) => setState(() => _hoveredDrawerIndex = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(color: isHovered ? tileBg : tileBg, borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: Container(width: 6, height: double.infinity, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
              title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              trailing: Icon(icon, color: iconColor),
              onTap: () {
                Navigator.of(context).pop(); // close drawer first
                setState(() => _currentIndex = index);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      );
    }

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
        _menuItem(index: 0, icon: Icons.home, label: 'Home', onTap: () {}),
        _menuItem(index: 1, icon: Icons.schedule, label: 'Timetable', onTap: () {}),
        _menuItem(index: 2, icon: Icons.event, label: 'Events', onTap: () {}),
        _menuItem(index: 3, icon: Icons.people, label: 'Users', onTap: () {}),
        _menuItem(index: 4, icon: Icons.person, label: 'Profile', onTap: () {}),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: InkWell(
            onTap: () async {
              // prompt confirmation before logout
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('Are you sure you want to sign out of this device?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Log out')),
                  ],
                ),
              );

              Navigator.of(context).pop(); // close drawer

              if (confirm == true) {
                // Navigate to LoginPage and clear navigation stack
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      isDark: widget.isDark,
                      onToggleTheme: widget.onToggleTheme,
                    ),
                  ),
                      (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout cancelled')));
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(color: widget.isDark ? Colors.red.withOpacity(0.08) : Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Container(width: 6, height: double.infinity, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6))),
                title: Text('Logout', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.logout, color: widget.isDark ? Colors.white : Colors.redAccent),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // AppBar with gradient and theme toggle
  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: widget.isDark ? [Colors.grey.shade900, Colors.grey.shade800] : const [Color(0xFF0D6EFD), Color(0xFF20C997)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        ),
      ),
      title: Row(children: [
        IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        const SizedBox(width: 8),
        const Expanded(child: Center(child: Text('Your University Name', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)))),
        IconButton(icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.white), onPressed: () => widget.onToggleTheme(!widget.isDark), tooltip: 'Toggle theme'),
      ]),
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      _buildTimetable(),
      _buildEvents(),
      _buildUsers(),
      _buildProfile(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // combine fade + slide
          final offsetAnimation = Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero).animate(animation);
          return FadeTransition(opacity: animation, child: SlideTransition(position: offsetAnimation, child: child));
        },
        child: SizedBox(key: ValueKey(_currentIndex), height: double.infinity, child: pages[_currentIndex]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: widget.isDark ? Colors.grey[900] : Colors.white,
        selectedItemColor: widget.isDark ? Colors.tealAccent : Colors.black87,
        unselectedItemColor: widget.isDark ? Colors.white70 : Colors.black45,
        items: [
          BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundColor: _paletteColor(0, opacity: 1.0), child: const Icon(Icons.home, size: 14, color: Colors.white)), label: 'Home'),
          BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundColor: _paletteColor(1, opacity: 1.0), child: const Icon(Icons.schedule, size: 14, color: Colors.white)), label: 'Timetable'),
          BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundColor: _paletteColor(2, opacity: 1.0), child: const Icon(Icons.event, size: 14, color: Colors.white)), label: 'Events'),
          BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundColor: _paletteColor(3, opacity: 1.0), child: const Icon(Icons.people, size: 14, color: Colors.white)), label: 'Users'),
          BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundColor: _paletteColor(4, opacity: 1.0), child: const Icon(Icons.person, size: 14, color: Colors.white)), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Dialog widget to manage event registrations with limit enforcement
class RegistrationDialog extends StatefulWidget {
  final String eventId;
  final List<Map<String, String>> users;
  final Set<String> registered;
  final int limit;
  final ValueChanged<Set<String>> onSave;

  const RegistrationDialog({
    Key? key,
    required this.eventId,
    required this.users,
    required this.registered,
    required this.limit,
    required this.onSave,
  }) : super(key: key);

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
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selected);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrations updated (demo)')));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// ProfilePage (kept largely as provided by the user but responsive)
class ProfilePage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  // Optional initial values
  final String initialName;
  final String initialEmail;
  final String initialDeptSection;
  final String initialPhotoUrl;

  const ProfilePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.initialName = 'John Doe',
    this.initialEmail = 'student@university.edu',
    this.initialDeptSection = 'CSE-B',
    this.initialPhotoUrl = 'https://images.unsplash.com/photo-1523580846011-d3a5bc25702b?auto=format&fit=crop&w=800&q=80',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String userName = widget.initialName;
  late String userEmail = widget.initialEmail;
  late String userDeptSection = widget.initialDeptSection;
  late String profileImage = widget.initialPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      children: [
        // Header with BTech student image
        Container(
          height: 180,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(profileImage),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.35), BlendMode.darken),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(radius: 36, backgroundImage: NetworkImage(profileImage)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                        Text('$userDeptSection • $userEmail', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(.9))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _changeProfileImage,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                    child: const Text('Change Photo'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Details & actions
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _settingTile(
                  icon: Icons.badge,
                  title: 'Name',
                  subtitle: userName,
                  onTap: () => _editTextField(context, title: 'Edit Name', initial: userName, onSave: (v) => setState(() => userName = v)),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.apartment,
                  title: 'Department & Section',
                  subtitle: userDeptSection,
                  onTap: () => _editTextField(context, title: 'Edit Department & Section', hint: 'e.g., CSE-B', initial: userDeptSection, onSave: (v) => setState(() => userDeptSection = v)),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: userEmail,
                  onTap: () => _editTextField(context, title: 'Edit Email', initial: userEmail, keyboardType: TextInputType.emailAddress, onSave: (v) => setState(() => userEmail = v)),
                ),
                _divider(),
                SwitchListTile(secondary: const Icon(Icons.dark_mode), title: const Text('Dark Mode'), value: widget.isDark, onChanged: widget.onToggleTheme),
              ]),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _settingTile(icon: Icons.lock, title: 'Change Password', subtitle: 'Update your password', onTap: () => _changePassword(context)),
                _divider(),
                _settingTile(icon: Icons.logout, title: 'Log out', subtitle: 'Sign out of this device', onTap: _logout),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  // --- helpers ---
  Widget _settingTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 0, indent: 16, endIndent: 16);

  void _changeProfileImage() {
    setState(() {
      profileImage = 'https://images.unsplash.com/photo-1525973132219-a04334a76080?auto=format&fit=crop&w=800&q=80';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
  }

  Future<void> _editTextField(BuildContext ctx, {required String title, required String initial, String? hint, TextInputType? keyboardType, required ValueChanged<String> onSave}) async {
    final controller = TextEditingController(text: initial);
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: hint), keyboardType: keyboardType, autofocus: true),
        actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')), FilledButton(onPressed: () {
          onSave(controller.text.trim());
          Navigator.pop(dCtx);
        }, child: const Text('Save'))],
      ),
    );
  }

  Future<void> _changePassword(BuildContext ctx) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
          const SizedBox(height: 8),
          TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 8),
          TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text || newCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password changed')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to sign out of this device?'),
        actions: [TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Log out'))],
      ),
    );
    if (ok == true) {
      // Navigate to LoginPage and clear navigation stack
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
            (route) => false,
      );
    }
  }
}
