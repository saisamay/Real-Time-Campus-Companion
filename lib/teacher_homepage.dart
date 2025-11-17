import 'package:flutter/material.dart';


class TeacherHomePage extends StatelessWidget {
  final String universityName;
  final String userName;
  final String userEmail;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const TeacherHomePage({
    super.key,
    required this.universityName,
    required this.userName,
    required this.userEmail,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    // The actual UI is implemented in TeachersHome (stateful).
    return TeachersHome(
      universityName: universityName,
      isDark: isDark,
      onToggleTheme: onToggleTheme,
    );
  }
}

// ----------------------- TEACHERS HOME (stateful) -----------------------
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
  String teacherName = 'Dr. Sharma';
  String teacherEmail = 'dr.sharma@university.edu';
  String department = 'CSE';
  String cabin = 'Block A - 305';

  // timetable slots & data
  final List<Map<String, String>> slots = [
    {'no': '1', 'time': '09:00'},
    {'no': '2', 'time': '09:50'},
    {'no': '3', 'time': '10:50'},
    {'no': '4', 'time': '11:40'},
    {'no': '5', 'time': '12:30'},
    {'no': '6', 'time': '13:20'},
    {'no': '7', 'time': '14:10'},
    {'no': '8', 'time': '15:10'},
    {'no': '9', 'time': '16:00'},
  ];

  Map<String, List<Map<String, String>>> teacherTimetable = {
    'Mon': [
      {'sub': 'Research', 'room': '', 'section': ''},
      {'sub': 'CSE-B', 'room': 'N106', 'section': 'B'},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'CSE-A', 'room': 'N105', 'section': 'A'},
      {'sub': 'Lunch', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'Meeting', 'room': 'Office', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
    ],
    'Tue': [
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'CSE-A', 'room': 'N105', 'section': 'A'},
      {'sub': 'CSE-A', 'room': 'N105', 'section': 'A'},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'Lunch', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'CSE-B', 'room': 'N106', 'section': 'B'},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
    ],
    'Wed': [
      {'sub': 'CSE-B', 'room': 'N106', 'section': 'B'},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'Faculty Meeting', 'room': 'Conf', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'Lunch', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'CSE-C', 'room': 'N107', 'section': 'C'},
      {'sub': '', 'room': '', 'section': ''},
    ],
    'Thu': [
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'CSE-C', 'room': 'N107', 'section': 'C'},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'CSE-D', 'room': 'N108', 'section': 'D'},
      {'sub': 'Lunch', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
    ],
    'Fri': [
      {'sub': 'CSE-B', 'room': 'N106', 'section': 'B'},
      {'sub': 'CSE-B', 'room': 'N106', 'section': 'B'},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': 'Lunch', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
      {'sub': '', 'room': '', 'section': ''},
    ],
  };

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
    setState(() => _index = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _openQuickSearch(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bCtx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(bCtx).viewInsets.bottom + 16),
        child: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search anything…', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
          onSubmitted: (q) {
            Navigator.pop(bCtx);
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Searching for: $q')));
          },
        ),
      ),
    );
  }

  void _updateTimetableCell(String day, int slotIndex, String subject, String room) {
    setState(() {
      final list = teacherTimetable[day]!;
      list[slotIndex] = {'sub': subject.trim(), 'room': room.trim(), 'section': list[slotIndex]['section'] ?? ''};
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timetable updated')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.universityName),
        leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())),
        actions: [Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.search), onPressed: () => _openQuickSearch(ctx), tooltip: 'Search')), const SizedBox(width: 8)],
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
            ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () { Navigator.pop(context); _goToPage(0); }),
            ListTile(leading: const Icon(Icons.meeting_room), title: const Text('Classrooms'), onTap: () { Navigator.pop(context); _goToPage(1); }),
            ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () { Navigator.pop(context); _goToPage(2); }),
          ],
        ),
      ),

      body: PageView(controller: _pageController, onPageChanged: (i) => setState(() => _index = i), children: [_teacherHome(context), const ClassroomsPage(), _teacherProfile(context)]),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Classrooms'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ---------------- TEACHER HOME ----------------
  Widget _teacherHome(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Weekly Timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TeacherTimetableWidget(timetable: teacherTimetable, slots: slots),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: NextClassCard(timetable: teacherTimetable, slots: slots)),

        const SizedBox(height: 20),
      ],
    );
  }

  // ---------------- TEACHER PROFILE ----------------
  Widget _teacherProfile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const CircleAvatar(radius: 40, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5")),
                const SizedBox(width: 16),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(teacherName, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(context, department, Icons.badge),
                    _chip(context, cabin, Icons.location_city),
                    _chip(context, teacherEmail, Icons.email),
                  ]),
                ])),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            _actionTile(context, icon: Icons.edit, label: 'Edit Name', onTap: () async {
              final ctrl = TextEditingController(text: teacherName);
              await showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Edit Name'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { setState(() => teacherName = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : teacherName); Navigator.pop(context); }, child: const Text('Save'))],
              ));
            }),
            _actionTile(context, icon: Icons.email, label: 'Edit Email', onTap: () async {
              final ctrl = TextEditingController(text: teacherEmail);
              await showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Edit Email'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { setState(() => teacherEmail = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : teacherEmail); Navigator.pop(context); }, child: const Text('Save'))],
              ));
            }),
            _actionTile(context, icon: Icons.home_work, label: 'Edit Cabin', onTap: () async {
              final ctrl = TextEditingController(text: cabin);
              await showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Edit Cabin'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { setState(() => cabin = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : cabin); Navigator.pop(context); }, child: const Text('Save'))],
              ));
            }),
            _actionTile(context, icon: Icons.event, label: 'Edit Timetable', onTap: () async { await _openTimetableEditor(context); }),
            _actionTile(context, icon: Icons.brightness_6, label: widget.isDark ? 'Light Mode' : 'Dark Mode', onTap: () => widget.onToggleTheme(!widget.isDark)),
          ]),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _chip(BuildContext context, String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.9), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: cs.onPrimaryContainer), const SizedBox(width: 6), Text(text, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _actionTile(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3))]),
        child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: cs.onPrimaryContainer)), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), const Icon(Icons.chevron_right)]),
      ),
    );
  }

  // Timetable editor
  Future<void> _openTimetableEditor(BuildContext context) async {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    String selectedDay = days.first;
    int selectedSlot = 0;
    final subjectCtrl = TextEditingController();
    final roomCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bCtx) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(bCtx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(bCtx).dividerColor, borderRadius: BorderRadius.circular(999)))]),
            const SizedBox(height: 12),
            const Text('Edit Timetable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (ctx, setStateSB) {
              return Column(children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
                  items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) { if (v != null) setStateSB(() => selectedDay = v); },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedSlot,
                  decoration: const InputDecoration(labelText: 'Slot (index starts 0)', border: OutlineInputBorder()),
                  items: List.generate(slots.length, (i) => DropdownMenuItem(value: i, child: Text('${i + 1} — ${slots[i]['time']}'))),
                  onChanged: (v) { if (v != null) setStateSB(() => selectedSlot = v); },
                ),
              ]);
            }),
            const SizedBox(height: 8),
            TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: FilledButton(onPressed: () {
              final sub = subjectCtrl.text.trim();
              final room = roomCtrl.text.trim();
              if (sub.isEmpty && room.isEmpty) { Navigator.pop(bCtx); return; }
              _updateTimetableCell(selectedDay, selectedSlot, sub, room);
              Navigator.pop(bCtx);
            }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Save'))))])
          ]),
        );
      },
    );
  }
}

// ------------------ CLASSROOMS PAGE (stateful) ------------------
class ClassroomsPage extends StatefulWidget {
  const ClassroomsPage({super.key});

  @override
  State<ClassroomsPage> createState() => _ClassroomsPageState();
}

class _ClassroomsPageState extends State<ClassroomsPage> {
  final Map<String, bool?> _roomStatus = {};
  final Map<String, String> _roomTypeOverride = {};

  String _filterType = 'Class';
  String _filterFloor = 'Ground';
  String _filterOccupancy = 'All';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var rooms = _generateRoomsExclusive(_filterType, _filterFloor);
    rooms = rooms.where((r) {
      final status = _roomStatus[r['name']!];
      if (_filterOccupancy == 'All') return true;
      if (_filterOccupancy == 'Occupied') return status == true;
      if (_filterOccupancy == 'Not occupied') return status == false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Classrooms')),
      body: Column(children: [
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _ResponsiveFilters(type: _filterType, floor: _filterFloor, occ: _filterOccupancy, onType: (v) => setState(() => _filterType = v), onFloor: (v) => setState(() => _filterFloor = v), onOcc: (v) => setState(() => _filterOccupancy = v))),

        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 4 / 3),
            itemCount: rooms.length,
            itemBuilder: (itemCtx, i) {
              final r = rooms[i];
              final name = r['name']!;
              final type = r['type']!;
              final floor = r['floor']!;
              final wing = r['wing']!;
              return InkWell(
                onTap: () => _showOccupancySheet(context, name, r['base']!, type),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(fit: StackFit.expand, children: [
                    Container(color: Colors.grey.shade200),
                    Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(8), child: _buildStatusPill(context, name))),
                    Align(alignment: Alignment.bottomLeft, child: Padding(padding: const EdgeInsets.all(10), child: Text(name, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)))),
                    Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.all(10), child: Text('$type • $floor', style: TextStyle(color: scheme.onSurfaceVariant)))),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  int _floorToInt(String floor) {
    switch (floor) {
      case 'Ground': return 0;
      case 'First': return 1;
      case 'Second': return 2;
      case 'Third': return 3;
      default: return 0;
    }
  }

  String _defaultTypeForBase(String base) {
    final digits = RegExp(r'\d+').firstMatch(base)?.group(0) ?? '0';
    final last = int.parse(digits[digits.length - 1]);
    return (last == 0 || last == 5) ? 'Lab' : 'Class';
  }

  List<Map<String, String>> _generateRoomsExclusive(String filterType, String floor) {
    final floorNum = _floorToInt(floor);
    final List<Map<String, String>> out = [];
    for (final wing in ['N', 'S']) {
      for (int i = 0; i <= 10; i++) {
        final roomNum = "$floorNum${i.toString().padLeft(2, '0')}";
        final base = '$wing$roomNum';
        final assigned = _roomTypeOverride[base] ?? _defaultTypeForBase(base);
        if (assigned == filterType) {
          final visibleName = assigned == 'Lab' ? '${base}L' : base;
          out.add({'name': visibleName, 'base': base, 'type': assigned, 'floor': floor, 'wing': wing});
        }
      }
    }
    out.sort((a, b) {
      if (a['wing'] != b['wing']) return a['wing']!.compareTo(b['wing']!);
      final na = int.parse(a['base']!.replaceAll(RegExp(r'[^0-9]'), ''));
      final nb = int.parse(b['base']!.replaceAll(RegExp(r'[^0-9]'), ''));
      return na.compareTo(nb);
    });
    return out;
  }

  void _showOccupancySheet(BuildContext ctx, String roomName, String base, String currentType) {
    final assigned = _roomTypeOverride[base];
    final effectiveType = assigned ?? currentType;
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(bCtx).dividerColor, borderRadius: BorderRadius.circular(999)))]),
          const SizedBox(height: 16),
          Text(roomName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Base: $base • Type: $effectiveType', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton.tonal(onPressed: () { setState(() => _roomStatus[roomName] = true); Navigator.pop(bCtx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Marked as Occupied'))); }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Occupied')))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { setState(() => _roomStatus[roomName] = false); Navigator.pop(bCtx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Marked as Not occupied'))); }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Not occupied')))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () { setState(() { _roomTypeOverride[base] = 'Class'; }); Navigator.pop(bCtx); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$base set as Class'))); }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Set as Class')))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(onPressed: () { setState(() { _roomTypeOverride[base] = 'Lab'; }); Navigator.pop(bCtx); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$base set as Lab'))); }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Set as Lab')))),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, String roomName) {
    final cs = Theme.of(context).colorScheme;
    final status = _roomStatus[roomName];
    if (status == true) return _pill('Occupied', cs.errorContainer, cs.onErrorContainer);
    if (status == false) return _pill('Not occupied', cs.primaryContainer, cs.onPrimaryContainer);
    return _pill('Unknown', cs.surfaceVariant, cs.onSurfaceVariant);
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(blurRadius: 8, offset: const Offset(0, 2), color: Colors.black.withOpacity(.15))]),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// -------- Responsive Filters --------
class _ResponsiveFilters extends StatelessWidget {
  final String type, floor, occ;
  final ValueChanged<String> onType, onFloor, onOcc;
  const _ResponsiveFilters({super.key, required this.type, required this.floor, required this.occ, required this.onType, required this.onFloor, required this.onOcc});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      final cols = w >= 900 ? 3 : (w >= 600 ? 2 : 1);
      final spacing = 12.0;
      final itemW = (w - (spacing * (cols - 1))) / cols;
      Widget box(Widget child) => SizedBox(width: itemW, child: child);

      return Wrap(spacing: spacing, runSpacing: spacing, children: [
        box(DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), items: const ['Class', 'Lab'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => onType(v!))),
        box(DropdownButtonFormField<String>(value: floor, decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), items: const ['Ground', 'First', 'Second', 'Third'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) => onFloor(v!))),
        box(DropdownButtonFormField<String>(value: occ, decoration: const InputDecoration(labelText: 'Filter', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), items: const ['All', 'Occupied', 'Not occupied'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) => onOcc(v!))),
      ]);
    });
  }
}

// ====================== TEACHER TIMETABLE WIDGET (ROW = slot, COL = day) ======================
class TeacherTimetableWidget extends StatelessWidget {
  final Map<String, List<Map<String, String>>> timetable;
  final List<Map<String, String>> slots;
  const TeacherTimetableWidget({super.key, required this.timetable, required this.slots});

  Color _colorForSection(String section) {
    switch (section) {
      case 'A': return const Color(0xFFDDF2FF);
      case 'B': return const Color(0xFFFFE5D9);
      case 'C': return const Color(0xFFE9F8E9);
      case 'D': return const Color(0xFFF3E8FF);
      default: return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final slotWidth = 90.0; // left column width for times

    // Ensure each day's list has exactly slots.length entries (pad with empty)
    Map<String, List<Map<String, String>>> padded = {};
    for (final d in weekdays) {
      final list = timetable[d] ?? [];
      final padList = List<Map<String, String>>.from(list);
      while (padList.length < slots.length) padList.add({'sub': '', 'room': '', 'section': ''});
      padded[d] = padList;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: slot index + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: slotWidth, height: 48, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 8), child: const Text('', style: TextStyle(fontWeight: FontWeight.bold))), // top-left blank
                ...List.generate(slots.length, (i) {
                  return Container(
                    width: slotWidth,
                    height: 64,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(6), color: Colors.grey.shade100),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('(${slots[i]['no']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(slots[i]['time']!, style: const TextStyle(fontSize: 12)),
                    ]),
                  );
                }),
              ],
            ),

            // For each day, a column of cells aligned with times
            ...weekdays.map((day) {
              final cells = padded[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 150, height: 48, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ...List.generate(slots.length, (i) {
                    final c = cells[i];
                    final section = (c['section'] ?? '').trim();
                    final filled = (c['sub'] ?? '').trim().isNotEmpty;
                    final bg = filled ? _colorForSection(section) : Colors.white;
                    return Container(
                      width: 150,
                      height: 64,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12), color: bg),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['sub'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text(c['room'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    );
                  }),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ----------------- Next class small card (no Slot shown) -----------------
class NextClassCard extends StatelessWidget {
  final Map<String, List<Map<String, String>>> timetable;
  final List<Map<String, String>> slots;
  const NextClassCard({super.key, required this.timetable, required this.slots});

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return h * 60 + m;
  }

  int _currentSlotIndex() {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    for (int i = 0; i < slots.length; i++) {
      final slotStart = _toMinutes(slots[i]['time']!);
      if (nowMinutes <= slotStart) return i;
    }
    return slots.length - 1;
  }

  Map<String, String>? _findNextClass() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final now = DateTime.now();
    final todayIndex = (now.weekday - 1) % 7;
    final slotStart = _currentSlotIndex();

    for (int d = 0; d < 7; d++) {
      final di = (todayIndex + d) % weekdays.length;
      final day = weekdays[di];
      final cells = timetable[day] ?? [];
      final startSlot = d == 0 ? slotStart : 0;
      for (int s = startSlot; s < cells.length; s++) {
        final c = cells[s];
        if ((c['sub'] ?? '').trim().isNotEmpty && c['sub'] != 'Lunch' && c['sub'] != 'Research') {
          return {'day': day, 'slot': (s + 1).toString(), 'sub': c['sub'] ?? '', 'room': c['room'] ?? ''};
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final next = _findNextClass();
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(12.0), child: Row(children: [
      const Icon(Icons.schedule, size: 36),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Next Class', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        if (next != null) Text('${next['sub']} • ${next['room']} • ${next['day']}') else const Text('No upcoming classes found'),
      ])),
    ])));
  }
}
