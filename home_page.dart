import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  runApp(const MyApp());
}

// ----------------------- APP -----------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // App-wide theme state
  bool _isDark = false;

  void _toggleTheme(bool value) {
    setState(() => _isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    // Professional palettes (light + dark)
    final light = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB), // Blue tone
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(height: 70, elevation: 2),
    );

    final dark = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(height: 70, elevation: 2),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University App',
      theme: light,
      darkTheme: dark,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        universityName: 'Your University',
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

// ----------------------- HOME -----------------------
class HomePage extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const HomePage({
    super.key,
    required this.universityName,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  late PageController _pageController;

  // ---- USER STATE (for Profile + Home preview) ----
  String userName = 'John Doe';
  String userEmail = 'student@university.edu';
  String userPassword = 'secret123'; // demo only

  // Keep department/section so Profile + Home Timetable preview can read it
  String selectedDept = 'CSE';
  String selectedSection = 'A';

  // ---- Classrooms occupancy state ----
  // true = occupied, false = not occupied, null = unknown
  final Map<String, bool?> _roomStatus = {};

  // ---- Filters for Classrooms tab ----
  String _filterType = 'Class';   // Class | Lab
  String _filterFloor = 'Ground'; // Ground | First | Second | Third

  // ---- IMAGES ----
  final List<String> eventImages = const [
    'https://images.unsplash.com/photo-1515168833906-d2a3b82b302a?auto=format&fit=crop&w=1200&q=70',
    'https://images.unsplash.com/photo-1531058020387-3be344556be6?auto=format&fit=crop&w=1200&q=70',
    'https://images.unsplash.com/photo-1573497019157-6caa24b4e45c?auto=format&fit=crop&w=1200&q=70',
  ];

  // Timetable images by Department -> Section (A/B/C/D)
  final Map<String, Map<String, List<String>>> timetableData = {
    'CSE': {
      'A': [
        'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=1200&q=70',
        'https://images.unsplash.com/photo-1581091012184-5c1e3d68f54d?auto=format&fit=crop&w=1200&q=70',
      ],
      'B': [
        'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=70',
      ],
      'C': [
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=70',
      ],
      'D': [
        'https://images.unsplash.com/photo-1531297484001-80022131f5a1?auto=format&fit=crop&w=1200&q=70',
      ],
    },
    'ECE': {
      'A': [
        'https://images.unsplash.com/photo-1581091870639-1e7b5e1b8b3c?auto=format&fit=crop&w=1200&q=70',
      ],
      'B': [
        'https://images.unsplash.com/photo-1518779578993-ec3579fee39f?auto=format&fit=crop&w=1200&q=70',
      ],
      'C': [
        'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=1200&q=70',
      ],
      'D': [
        'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=70',
      ],
    },
    'EEE': {
      'A': [
        'https://images.unsplash.com/photo-1590608897129-79da98d15971?auto=format&fit=crop&w=1200&q=70',
      ],
      'B': [
        'https://images.unsplash.com/photo-1591696205602-2f950c417cb9?auto=format&fit=crop&w=1200&q=70',
      ],
      'C': [
        'https://images.unsplash.com/photo-1542751110-97427bbecf20?auto=format&fit=crop&w=1200&q=70',
      ],
      'D': [
        'https://images.unsplash.com/photo-1555949963-aa79dcee981d?auto=format&fit=crop&w=1200&q=70',
      ],
    },
    'Mechanical': {
      'A': [
        'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=70',
      ],
      'B': [
        'https://images.unsplash.com/photo-1581090464777-6f3f1a1f99c5?auto=format&fit=crop&w=1200&q=70',
      ],
      'C': [
        'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=70',
      ],
      'D': [
        'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=1200&q=70',
      ],
    },
    'Biotech': {
      'A': [
        'https://images.unsplash.com/photo-1581090700227-1e37b190418e?auto=format&fit=crop&w=1200&q=70',
      ],
      'B': [
        'https://images.unsplash.com/photo-1579154204601-01588f351e9b?auto=format&fit=crop&w=1200&q=70',
      ],
      'C': [
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=70',
      ],
      'D': [
        'https://images.unsplash.com/photo-1581091215367-59ab6b321434?auto=format&fit=crop&w=1200&q=70',
      ],
    },
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

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // APP BAR with MENU BUTTON
      appBar: AppBar(
        title: Text(widget.universityName),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          // Search icon
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _openQuickSearch(ctx),
              tooltip: 'Search',
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      // DRAWER (auto-closes on tap)
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
                  ),
                  const SizedBox(height: 12),
                  Text("Student Name", style: TextStyle(color: scheme.onPrimary, fontSize: 18)),
                  Text("student@university.edu",
                      style: TextStyle(color: scheme.onPrimary.withOpacity(.8), fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                _goToPage(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text("Timetable"),
              onTap: () {
                Navigator.pop(context);
                _goToPage(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text("Classrooms"),
              onTap: () {
                Navigator.pop(context);
                _goToPage(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text("Friends Classroom"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FriendsClassroomPage(
                      friends: [
                        FriendModel(name: 'Aarav', room: 'CSE Lab 101', avatarUrl: 'https://i.pravatar.cc/150?img=12'),
                        FriendModel(name: 'Diya', room: 'ECE Room 202', avatarUrl: 'https://i.pravatar.cc/150?img=32'),
                        FriendModel(name: 'Rahul', room: 'EEE Lab 109', avatarUrl: 'https://i.pravatar.cc/150?img=15'),
                        FriendModel(name: 'Sneha', room: 'Mech Workshop', avatarUrl: 'https://i.pravatar.cc/150?img=47'),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chair_alt),
              title: const Text("Teachers Cabin"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeachersCabinPage()));
              },
            ),
          ],
        ),
      ),

      // BODY with swipe (now 5 tabs including Profile)
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          _homePage(context),                 // 0
          const TimetablePage(embedded: true),// 1  <-- NEW grid timetable
          _eventsPage(context),               // 2
          _classroomsTab(context),            // 3
          _profilePage(context),              // 4
        ],
      ),

      // FOOTER: added Profile as 5th tab
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Timetable'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Classrooms'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _openQuickSearch(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(bCtx).viewInsets.bottom + 16,
        ),
        child: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search anything…',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (q) {
            Navigator.pop(bCtx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Searching for: $q')),
            );
          },
        ),
      ),
    );
  }

  void _goToPage(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ---------- HOME ----------
  Widget _homePage(BuildContext context) {
    final imagesForPreview = timetableData[selectedDept]?[selectedSection] ?? const <String>[];
    final previewImage = imagesForPreview.isNotEmpty ? imagesForPreview.first : null;

    return ListView(
      children: [
        const SizedBox(height: 16),
        // Events slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CarouselSlider(
              options:  CarouselOptions(
                height: 230.0,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                autoPlayInterval: Duration(seconds: 3),
              ),
              items: eventImages
                  .map((url) => Image.network(url, fit: BoxFit.cover, width: double.infinity))
                  .toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bigger Timetable preview card
        if (previewImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 220, width: double.infinity, child: Image.network(previewImage, fit: BoxFit.cover)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$selectedDept - $selectedSection',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _goToPage(1),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('View Timetable'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Announcements
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text("Announcements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const ListTile(
          leading: Icon(Icons.campaign),
          title: Text("Tech Fest this weekend!"),
          subtitle: Text("Don't miss the cultural night."),
        ),
        const ListTile(
          leading: Icon(Icons.book),
          title: Text("Library open till 10 PM"),
          subtitle: Text("Extended hours for exams."),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ---------- EVENTS ----------
  Widget _eventsPage(BuildContext context) => Column(
    children: [
      const SizedBox(height: 16),
      CarouselSlider(
        options:  CarouselOptions(
          height: 220.0,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
          autoPlayInterval: Duration(seconds: 3),
        ),
        items: eventImages
            .map((url) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
        ))
            .toList(),
      ),
      const SizedBox(height: 20),
      const Text("Upcoming Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Join our Annual Tech Fest and Cultural Week starting this Friday!",
            textAlign: TextAlign.center),
      ),
    ],
  );

  // ---------- CLASSROOMS TAB (footer index 3) ----------
  Widget _classroomsTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Floor name -> number mapping
    int _floorToInt(String floor) {
      switch (floor) {
        case 'Ground': return 0;
        case 'First':  return 1;
        case 'Second': return 2;
        case 'Third':  return 3;
        default:       return 0;
      }
    }

    // Generate room list for current filters
    List<Map<String, String>> _generateRooms(String type, String floor) {
      final floorNum = _floorToInt(floor);
      final List<Map<String, String>> out = [];
      for (final wing in ['N', 'S']) {
        for (int i = 0; i <= 10; i++) {
          final roomNum = "$floorNum${i.toString().padLeft(2, '0')}"; // 000..010, 100..110, etc.
          final code = '$wing$roomNum${type == "Lab" ? "L" : ""}';
          out.add({
            'name': code,
            'type': type,
            'floor': floor,
            'wing': wing,
          });
        }
      }
      // Order by Wing (N first), then numeric part
      out.sort((a, b) {
        if (a['wing'] != b['wing']) return a['wing']!.compareTo(b['wing']!);
        final na = int.parse(a['name']!.replaceAll(RegExp(r'[^0-9]'), ''));
        final nb = int.parse(b['name']!.replaceAll(RegExp(r'[^0-9]'), ''));
        return na.compareTo(nb);
      });
      return out;
    }

    final types = const ['Class', 'Lab'];
    final floors = const ['Ground', 'First', 'Second', 'Third'];

    final rooms = _generateRooms(_filterType, _filterFloor);

    return Column(
      children: [
        const SizedBox(height: 10),

        // Filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _filterType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterFloor,
                  decoration: const InputDecoration(
                    labelText: 'Floor',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: floors.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _filterFloor = v!),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Grid of cards (no images; code + status)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 4 / 3,
            ),
            itemCount: rooms.length,
            itemBuilder: (ctx, i) {
              final r = rooms[i];
              final name = r['name']!;
              return InkWell(
                onTap: () => _showOccupancySheet(context, name),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: code + pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                                fontSize: 16,
                              ),
                            ),
                            _buildStatusPill(context, name),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${r['type']} • ${r['floor']} Floor • ${r['wing']} Wing',
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ------- Occupancy helpers -------
  void _showOccupancySheet(BuildContext ctx, String roomName) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(bCtx).dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(roomName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {
                        setState(() => _roomStatus[roomName] = true);
                        Navigator.pop(bCtx);
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(const SnackBar(content: Text('Marked as Occupied')));
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Occupied', textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _roomStatus[roomName] = false);
                        Navigator.pop(bCtx);
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(const SnackBar(content: Text('Marked as Not occupied')));
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Not occupied', textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(BuildContext context, String roomName) {
    final cs = Theme.of(context).colorScheme;
    final status = _roomStatus[roomName];

    String label;
    Color bg;
    Color fg;

    if (status == true) {
      label = 'Occupied';
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    } else if (status == false) {
      label = 'Not occupied';
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    } else {
      label = 'Unknown';
      bg = cs.surfaceVariant;
      fg = cs.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(blurRadius: 8, offset: const Offset(0, 2), color: Colors.black.withOpacity(.15))],
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // ---------- PROFILE (footer index 4) ----------
  Widget _profilePage(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deptSection = '$selectedDept - $selectedSection';

    return ListView(
      children: [
        // Header
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, cs.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 40, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3")),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [
                            _chip(context, deptSection, Icons.badge),
                            _chip(context, userEmail, Icons.email),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionTile(
                context,
                icon: Icons.edit,
                label: 'Edit Name',
                onTap: () async {
                  final ctrl = TextEditingController(text: userName);
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Edit Name'),
                      content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () {
                            setState(() => userName = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : userName);
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _actionTile(
                context,
                icon: Icons.email,
                label: 'Edit Email',
                onTap: () async {
                  final ctrl = TextEditingController(text: userEmail);
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Edit Email'),
                      content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () {
                            setState(() => userEmail = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : userEmail);
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _actionTile(
                context,
                icon: Icons.brightness_6,
                label: widget.isDark ? 'Light Mode' : 'Dark Mode',
                onTap: () => widget.onToggleTheme(!widget.isDark),
              ),
            ],
          ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// ------------------ CLASSROOMS PAGE (standalone push) ------------------
class ClassroomsPage extends StatelessWidget {
  const ClassroomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageContext = context; // scaffold-aware context
    final scheme = Theme.of(context).colorScheme;

    final rooms = [
      {'name': 'CSE Lab 101', 'cap': 36, 'img': 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=70'},
      {'name': 'ECE Room 202', 'cap': 48, 'img': 'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=1200&q=70'},
      {'name': 'EEE Lab 109', 'cap': 24, 'img': 'https://images.unsplash.com/photo-1542751110-97427bbecf20?auto=format&fit=crop&w=1200&q=70'},
      {'name': 'Mech Workshop', 'cap': 30, 'img': 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=70'},
      {'name': 'Biotech Lab B1', 'cap': 20, 'img': 'https://images.unsplash.com/photo-1581090700227-1e37b190418e?auto=format&fit=crop&w=1200&q=70'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Classrooms')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 4 / 3,
        ),
        itemCount: rooms.length,
        itemBuilder: (itemCtx, i) {
          final r = rooms[i];
          return InkWell(
            onTap: () {
              ScaffoldMessenger.of(pageContext).showSnackBar(
                SnackBar(content: Text('${r['name']} • Capacity: ${r['cap']}')),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(r['img'] as String, fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(0.25)),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '${r['name']}',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------ FRIENDS CLASSROOM PAGE ------------------
class FriendModel {
  final String name;
  final String room;
  final String avatarUrl;

  FriendModel({required this.name, required this.room, required this.avatarUrl});
}

class FriendsClassroomPage extends StatelessWidget {
  final List<FriendModel> friends;
  const FriendsClassroomPage({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    final pageContext = context;

    return Scaffold(
      appBar: AppBar(title: const Text('Friends Classroom')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: friends.length,
        itemBuilder: (_, i) {
          final f = friends[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(f.avatarUrl)),
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Currently in: ${f.room}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(content: Text('${f.name} is in ${f.room}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ------------------ TEACHERS CABIN PAGE ------------------
class TeachersCabinPage extends StatelessWidget {
  const TeachersCabinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageContext = context;
    final scheme = Theme.of(context).colorScheme;

    final teachers = [
      {'name': 'Dr. Sharma', 'dept': 'CSE', 'cabin': 'Block A - 305', 'img': 'https://i.pravatar.cc/150?img=5'},
      {'name': 'Prof. Nair', 'dept': 'ECE', 'cabin': 'Block B - 210', 'img': 'https://i.pravatar.cc/150?img=9'},
      {'name': 'Dr. Gupta', 'dept': 'EEE', 'cabin': 'Block C - 118', 'img': 'https://i.pravatar.cc/150?img=22'},
      {'name': 'Prof. Rao', 'dept': 'Mechanical', 'cabin': 'Block D - 402', 'img': 'https://i.pravatar.cc/150?img=36'},
      {'name': 'Dr. Iyer', 'dept': 'Biotech', 'cabin': 'Block E - 127', 'img': 'https://i.pravatar.cc/150?img=41'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Teachers Cabin')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: teachers.length,
        itemBuilder: (_, i) {
          final t = teachers[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(t['img'] as String)),
              title: Text('${t['name']} • ${t['dept']}'),
              subtitle: Text('Cabin: ${t['cabin']}'),
              trailing: Icon(Icons.chair_alt, color: scheme.primary),
              onTap: () {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(content: Text("${t['name']} — ${t['cabin']}")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ====================== NEW GRID TIMETABLE PAGE ======================
class TimetablePage extends StatefulWidget {
  /// When true, renders just the content (no Scaffold/AppBar) so it can live inside a tab.
  final bool embedded;
  const TimetablePage({super.key, this.embedded = false});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  // UI selectors
  String selectedSemester = 'S5';
  String selectedBranch = 'EEE';
  String selectedSection = 'N302';

  final List<String> semesters = ['S3', 'S4', 'S5', 'S6'];
  final List<String> branches = ['CSE', 'EEE', 'MECH', 'CIVIL'];
  final List<String> sections = ['N301', 'N302', 'N303', 'N304'];

  // Define the time slots (slot number + start-end)
  final List<Map<String, String>> slots = [
    {'no': '1', 'time': '9:00 - 9:50'},
    {'no': '2', 'time': '9:50 - 10:40'},
    {'no': '3', 'time': '10:50 - 11:40'},
    {'no': '4', 'time': '11:40 - 12:30'},
    {'no': '5', 'time': '12:30 - 1:20'},
    {'no': '6', 'time': '1:20 - 2:10'},
    {'no': '7', 'time': '2:10 - 3:00'},
    {'no': '8', 'time': '3:10 - 4:00'},
    {'no': '9', 'time': '4:00 - 4:50'},
  ];

  // Example timetable data
  Map<String, List<Map<String, String>>> timetableData = {
    'Mon': [
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE303', 'subtitle': '', 'color': '#FFB85C'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': '23EEE301', 'subtitle': '', 'color': '#659CD8'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE301', 'subtitle': '', 'color': '#659CD8'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
    'Tue': [
      {'title': 'CIR-23LSE301\nVerbal Skills', 'subtitle': '', 'color': '#F4DDB3'},
      {'title': 'CIR-23LSE301\nAptitude Skills', 'subtitle': '', 'color': '#F4DDB3'},
      {'title': 'Counselling Hour', 'subtitle': '', 'color': '#FF5C5C'},
      {'title': '23EEE351\n23EEE369', 'subtitle': '23ELC366', 'color': '#8BD9FF'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE367\n23EEE335', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE381', 'subtitle': '23EEE382', 'color': '#FFF799'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
    'Wed': [
      {'title': '23EEE302', 'subtitle': '', 'color': '#6A3F8A'},
      {'title': '23EEE303', 'subtitle': '', 'color': '#C75B3A'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE367', 'subtitle': '', 'color': '#F7C94E'},
      {'title': '23EEE302', 'subtitle': '', 'color': '#6A3F8A'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': 'Tutorial 1', 'subtitle': '', 'color': '#2CB36A'},
      {'title': 'Tutorial 2', 'subtitle': '', 'color': '#2CB36A'},
    ],
    'Thu': [
      {'title': '23EEE367\n23EEE335', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE381\n23EEE382', 'subtitle': '', 'color': '#FFF799'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE351', 'subtitle': '23EEE369', 'color': '#8BD9FF'},
      {'title': 'CIR-23LSE301\nSoft Skills', 'subtitle': 'N112C', 'color': '#F4DDB3'},
      {'title': 'CIR-23LSE301\nCode HR', 'subtitle': 'A202', 'color': '#F4DDB3'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
    'Fri': [
      {'title': '23EEE301', 'subtitle': '', 'color': '#2A5DA8'},
      {'title': '23EEE303', 'subtitle': '', 'color': '#C75B3A'},
      {'title': '23EEE302', 'subtitle': '', 'color': '#6A3F8A'},
      {'title': '23EEE301', 'subtitle': '', 'color': '#2A5DA8'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE335', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
      {'title': '23EEE351', 'subtitle': '23EEE369\n23ELC366', 'color': '#8BD9FF'},
      {'title': 'Tutorial 3', 'subtitle': '', 'color': '#2CB36A'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
  };

  // Helper to convert color hex string to Color
  Color hexToColor(String hex) {
    String cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    return Color(int.parse(cleaned, radix: 16));
  }

  // When you change selectors, you may fetch fresh data from backend
  void _onSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching: $selectedSemester / $selectedBranch / $selectedSection')),
    );
    setState(() {});
  }

  // Show bottom sheet with details of the cell
  void _showCellDetails(String day, int slotIndex, Map<String, String> cell) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: [
                ListTile(
                  title: Text(cell['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(cell['subtitle'] ?? ''),
                ),
                const Divider(),
                ListTile(title: Text('Day: $day')),
                ListTile(title: Text('Slot: ${slots[slotIndex]['no']}  •  ${slots[slotIndex]['time']}')),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the whole timetable as a scrollable table-like widget
  Widget _buildTimetable() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // header row for slot times and numbers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120), // empty cell for top-left
              ...slots.map((s) => Container(
                width: 160,
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                child: Column(
                  children: [
                    Text(s['time']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('(${s['no']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
            ],
          ),
          // rows for each day
          ...days.map((day) {
            final cells = timetableData[day]!;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // day label
                Container(
                  width: 120,
                  height: 90,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.black12)),
                  child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                // cells
                ...List.generate(cells.length, (index) {
                  final cell = cells[index];
                  final bg = hexToColor(cell['color'] ?? '#FFFFFFFF');
                  final title = cell['title'] ?? '';
                  final subtitle = cell['subtitle'] ?? '';
                  return GestureDetector(
                    onTap: () => _showCellDetails(day, index, cell),
                    child: Container(
                      width: 160,
                      height: 90,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 11)),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text('(${slots[index]['no']})', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          )
                        ],
                      ),
                    ),
                  );
                })
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // Build the control row (semester/branch/section + search)
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Semester
          SizedBox(
            width: 140,
            child: InputDecorator(
              decoration: const InputDecoration(label: Text('Semester'), border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedSemester,
                  items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() { if (v != null) selectedSemester = v; }),
                ),
              ),
            ),
          ),

          // Branch
          SizedBox(
            width: 140,
            child: InputDecorator(
              decoration: const InputDecoration(label: Text('Branch'), border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedBranch,
                  items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() { if (v != null) selectedBranch = v; }),
                ),
              ),
            ),
          ),

          // Section
          SizedBox(
            width: 140,
            child: InputDecorator(
              decoration: const InputDecoration(label: Text('Section'), border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedSection,
                  items: sections.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() { if (v != null) selectedSection = v; }),
                ),
              ),
            ),
          ),

          ElevatedButton.icon(
            onPressed: _onSearch,
            icon: const Icon(Icons.search),
            label: const Text('Search'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
          ),
        ],
      ),
    );
  }

  // Build the legend/modal that shows slot numbers and times
  Widget _buildSlotLegend() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: slots.map((s) {
            return Container(
              width: 160,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text('Slot ${s['no']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(s['time']!, textAlign: TextAlign.center),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildControls(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTimetable(),
                _buildSlotLegend(),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      // Use inside your PageView tab (no AppBar/Scaffold)
      return content;
    }

    // Standalone screen (if you ever push it via Navigator)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Table'),
        centerTitle: true,
      ),
      body: content,
    );
  }
}
