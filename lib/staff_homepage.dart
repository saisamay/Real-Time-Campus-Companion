// lib/staff_homepage.dart
import 'package:flutter/material.dart';
import 'main.dart';
import 'profile_page.dart';
// for LoginPage navigation

class StaffHomePage extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String userName;
  final String userEmail;

  const StaffHomePage({
    super.key,
    required this.universityName,
    required this.isDark,
    required this.onToggleTheme,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _index = 0;
  late PageController _pageController;

  // Profile info — initialized from widget values
  late String staffName;
  late String staffEmail;
  String department = 'Administration';
  String office = 'Block B - 102';

  // simple in-memory password (for demo)
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
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.universityName),
        leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _openQuickSearch(context)),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const CircleAvatar(radius: 28, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=11")),
                const SizedBox(height: 12),
                Text(staffName, style: TextStyle(color: scheme.onPrimary, fontSize: 18)),
                Text(staffEmail, style: TextStyle(color: scheme.onPrimary.withOpacity(.8), fontSize: 14)),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // close drawer then navigate to LoginPage (clear stack)
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
          const ClassroomsPage(),
          _profilePage(context),
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

  Widget _profilePage(BuildContext context) {
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
                const CircleAvatar(radius: 40, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=11")),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(staffName, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(staffEmail, style: TextStyle(color: cs.onPrimary.withOpacity(.9))),
                    const SizedBox(height: 6),
                    Text('$department • $office', style: TextStyle(color: cs.onPrimary.withOpacity(.9))),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            _actionTile(context,
              icon: Icons.edit,
              label: 'Edit Name',
              onTap: () async {
                final ctrl = TextEditingController(text: staffName);
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Edit Name'),
                    content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      FilledButton(onPressed: () {
                        setState(() => staffName = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : staffName);
                        Navigator.pop(context);
                      }, child: const Text('Save')),
                    ],
                  ),
                );
              },
            ),
            _actionTile(context,
              icon: widget.isDark ? Icons.light_mode : Icons.dark_mode,
              label: widget.isDark ? 'Light Mode' : 'Dark Mode',
              onTap: () => widget.onToggleTheme(!widget.isDark),
            ),
            _actionTile(context,
              icon: Icons.lock,
              label: 'Change Password',
              onTap: () async {
                await _showChangePasswordDialog(context);
              },
            ),
          ]),
        ),
      ],
    );
  }

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _ResponsiveFilters(
            type: _filterType,
            floor: _filterFloor,
            occ: _filterOccupancy,
            onType: (v) => setState(() => _filterType = v),
            onFloor: (v) => setState(() => _filterFloor = v),
            onOcc: (v) => setState(() => _filterOccupancy = v),
          ),
        ),
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
      case 'Ground':
        return 0;
      case 'First':
        return 1;
      case 'Second':
        return 2;
      case 'Third':
        return 3;
      default:
        return 0;
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
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  setState(() => _roomStatus[roomName] = true);
                  Navigator.pop(bCtx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Marked as Occupied')));
                },
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Occupied')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  setState(() => _roomStatus[roomName] = false);
                  Navigator.pop(bCtx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Marked as Not occupied')));
                },
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Not occupied')),
              ),
            ),
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
        box(DropdownButtonFormField<String>(
          value: type,
          decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: const ['Class', 'Lab'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => onType(v!),
        )),
        box(DropdownButtonFormField<String>(
          value: floor,
          decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: const ['Ground', 'First', 'Second', 'Third'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: (v) => onFloor(v!),
        )),
        box(DropdownButtonFormField<String>(
          value: occ,
          decoration: const InputDecoration(labelText: 'Filter', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: const ['All', 'Occupied', 'Not occupied'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: (v) => onOcc(v!),
        )),
      ]);
    });
  }
}
