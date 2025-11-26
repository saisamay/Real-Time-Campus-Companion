import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'main.dart';
import 'student_timetable_page.dart';
import 'emptyclassrooms_page.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class TeacherHomePage extends StatelessWidget {
  final String universityName;
  final String userName;
  final String userEmail;
  final String? userId; // Critical for API updates
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  const TeacherHomePage({
    super.key,
    required this.universityName,
    required this.userName,
    required this.userEmail,
    this.userId,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return TeachersHome(
      universityName: universityName,
      isDark: isDark,
      onToggleTheme: onToggleTheme,
      userName: userName,
      userEmail: userEmail,
      userId: userId,
    );
  }
}

class TeachersHome extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String userName;
  final String userEmail;
  final String? userId;

  const TeachersHome({
    super.key,
    required this.universityName,
    required this.isDark,
    required this.onToggleTheme,
    required this.userName,
    required this.userEmail,
    this.userId,
  });

  @override
  State<TeachersHome> createState() => _TeachersHomeState();
}

class _TeachersHomeState extends State<TeachersHome> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Profile info
  late String teacherName;
  late String teacherEmail;
  String department = 'CSE';
  String cabin = 'Block A - 305';
  String profileImage = 'https://i.pravatar.cc/150?img=5';
  String? _userId;

  // Local state
  late bool _localIsDark;
  bool _isAvailable = true; // Default, will sync with DB

  // --- Dynamic Timetable State ---
  bool _isTimetableLoading = true;
  List<TimetableDay> _timetableGrid = [];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  // Time Slots for Grid Header
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

  // --- ANIMATION CONTROLLERS ---
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;
  late Animation<double> _headerScale;
  late Animation<double> _headerFade;
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    teacherName = widget.userName.isNotEmpty ? widget.userName : 'Dr. Sharma';
    teacherEmail = widget.userEmail.isNotEmpty ? widget.userEmail : 'dr.sharma@university.edu';
    _localIsDark = widget.isDark;

    if (widget.userId != null) _userId = widget.userId;

    _loadUserData();
    _loadTimetableData();

    // Animations
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _cardsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _headerScale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeIn));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _cardSlides = List.generate(6, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardsController, curve: Interval(i * 0.1, 0.5 + (i * 0.1), curve: Curves.easeOutCubic)));
    });

    _headerController.forward();
    _cardsController.forward();
  }

  // --- 1. Load User Data (Cabin, Avail, Photo) ---
  Future<void> _loadUserData() async {
    try {
      // Try local storage first
      final userProfile = await ApiService.readUserProfile();
      String? idToUse = _userId ?? userProfile?['_id'] ?? userProfile?['id'];

      if (idToUse != null) {
        try {
          // Fetch fresh from API
          final freshData = await ApiService.getUserById(idToUse);
          if (mounted) {
            setState(() {
              _userId = idToUse;
              if (freshData.containsKey('availability')) {
                _isAvailable = freshData['availability'] == true;
              }
              if (freshData['cabinRoom'] != null) {
                cabin = freshData['cabinRoom'];
              }
              if (freshData['profile'] != null && freshData['profile']['url'] != null) {
                profileImage = freshData['profile']['url'];
              }
            });
          }
        } catch (e) {
          // API failed, use local storage fallback
          if (mounted && userProfile != null) {
            setState(() {
              if (userProfile['cabinRoom'] != null) cabin = userProfile['cabinRoom'];
              if (userProfile.containsKey('availability')) {
                _isAvailable = userProfile['availability'] == true;
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  // --- 2. Load Timetable ---
  Future<void> _loadTimetableData() async {
    try {
      final grid = await ApiService.getTeacherTimetable();
      if (mounted) {
        setState(() {
          _timetableGrid = grid;
          _isTimetableLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isTimetableLoading = false);
    }
  }

  // --- 3. Update Availability ---
  Future<void> _updateAvailability(bool val) async {
    setState(() => _isAvailable = val);

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User ID missing. Re-login.'), backgroundColor: Colors.red));
      return;
    }

    try {
      await ApiService.updateUserById(id: _userId!, availability: val);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Marked Available' : 'Marked Busy'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
    } catch (e) {
      setState(() => _isAvailable = !val); // Revert UI
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red));
    }
  }

  // --- 4. Update Class Slot (Cancel/Room Change) ---
  Future<void> _updateSlot(String contextStr, String day, int index, bool isCancelled, String? newRoom) async {
    try {
      final parts = contextStr.split(' ');
      if (parts.length < 3) return; // Safety check

      await ApiService.updateSlot(
        branch: parts[0],
        semester: parts[1],
        section: parts[2],
        dayName: day,
        slotIndex: index,
        isCancelled: isCancelled,
        newRoom: newRoom,
      );

      Navigator.pop(context); // Close sheet
      _loadTimetableData(); // Refresh grid
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class Updated!'), backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showSlotDetails(TimetableSlot slot, String day, int index) {
    final roomCtrl = TextEditingController(text: slot.newRoom ?? slot.room);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Class: ${slot.displayContext}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 8),
            Text(slot.courseName, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Cancel Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cancel This Class'),
              value: slot.isCancelled,
              activeColor: Colors.red,
              onChanged: (val) => _updateSlot(slot.displayContext, day, index, val, null),
            ),
            const SizedBox(height: 10),

            // Room Change
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Change Room (Optional)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _updateSlot(slot.displayContext, day, index, slot.isCancelled, roomCtrl.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Gradient ---
  LinearGradient get _headerGradient => _localIsDark
      ? const LinearGradient(colors: [Color(0xFF1F1F1F), Color(0xFF121212)], begin: Alignment.topLeft, end: Alignment.bottomRight)
      : const LinearGradient(colors: [Color(0xFF0D6EFD), Color(0xFF20C997)], begin: Alignment.topLeft, end: Alignment.bottomRight);

  List<Color> get _palette => [const Color(0xFF0D6EFD), const Color(0xFF20C997), const Color(0xFFFFA927), const Color(0xFF8A63D2), const Color(0xFFEF476F)];
  Color _paletteColor(int index, {double opacity = 1.0}) => _palette[index % _palette.length].withOpacity(opacity);

  @override
  void dispose() {
    _pageController.dispose();
    _headerController.dispose();
    _cardsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    if (index == 3) { // Reset animations for profile page
      _headerController.reset();
      _cardsController.reset();
      _headerController.forward();
      _cardsController.forward();
    }
  }

  // --- UI BUILDERS ---

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(decoration: BoxDecoration(gradient: _headerGradient)),
      title: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          const Expanded(child: Center(child: Text('Teacher Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          IconButton(
            icon: const Icon(Icons.brightness_medium, color: Colors.white),
            onPressed: () {
              setState(() => _localIsDark = !_localIsDark);
              widget.onToggleTheme(_localIsDark);
            },
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    Widget item(int idx, IconData icon, String label) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: _localIsDark ? Colors.white : _paletteColor(idx)),
        title: Text(label, style: TextStyle(color: _localIsDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        onTap: () { Navigator.pop(context); _goToPage(idx); },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: _currentIndex == idx ? _paletteColor(idx, opacity: 0.1) : null,
      ),
    );

    return Drawer(
      backgroundColor: _localIsDark ? Colors.grey.shade900 : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(gradient: _headerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 28, backgroundImage: NetworkImage(profileImage)),
                const SizedBox(height: 10),
                Text(teacherName, style: const TextStyle(color: Colors.white, fontSize: 18)),
                const Text('Faculty Member', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          item(0, Icons.home, 'Home'),
          item(2, Icons.meeting_room, 'Classrooms'),
          item(3, Icons.person, 'Profile'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage(isDark: _localIsDark, onToggleTheme: widget.onToggleTheme)),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      backgroundColor: _localIsDark ? const Color(0xFF121212) : Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: [
          _buildHome(),
          const StudentTimetablePage(userRole: 'teacher'), // Pass teacher role to enable edit features
          const EmptyClassroomsPage(),
          _teacherProfile(context),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _localIsDark ? Colors.grey.shade900 : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _goToPage,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _localIsDark ? Colors.white : Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Timetable'),
            BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Classrooms'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _headerGradient,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 30, backgroundImage: NetworkImage(profileImage)),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back,', style: TextStyle(color: Colors.white70)),
                    Text(teacherName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('$department • $cabin', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Cabin Status Toggle
                CabinStatusCard(isAvailable: _isAvailable, onChanged: _updateAvailability),
                const SizedBox(height: 16),

                // Next Class Card (Passes real data if available)
                NextClassCard(grid: _timetableGrid, slots: slots),
                const SizedBox(height: 24),

                const Text('Weekly Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Dynamic Grid
                _isTimetableLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _timetableGrid.isEmpty
                    ? const Center(child: Text('No classes found.'))
                    : _buildTimetableGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableGrid() {
    final Map<String, List<TimetableSlot>> gridMap = {};
    for (var d in _timetableGrid) gridMap[d.dayName] = d.slots;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Times)
          Row(
            children: [
              Container(width: 60), // Spacer for Day Column
              ...slots.map((s) => Container(
                width: 100,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: Text(s['time']!, style: TextStyle(color: _localIsDark ? Colors.white70 : Colors.grey[800], fontSize: 12)),
              )),
            ],
          ),
          // Data Rows
          ..._days.map((day) {
            final daySlots = gridMap[day] ?? List.filled(9, TimetableSlot());
            return Row(
              children: [
                // Day Label
                Container(
                  width: 60,
                  height: 80,
                  alignment: Alignment.center,
                  child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: _localIsDark ? Colors.white : Colors.black)),
                ),
                // Slots
                ...List.generate(9, (idx) {
                  final slot = daySlots.length > idx ? daySlots[idx] : TimetableSlot();
                  final hasClass = slot.courseCode.isNotEmpty;

                  Color bg = _localIsDark ? Colors.white10 : Colors.white;
                  if (hasClass) bg = _localIsDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50;
                  if (slot.isCancelled) bg = _localIsDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;

                  return GestureDetector(
                    onTap: hasClass ? () => _showSlotDetails(slot, day, idx) : null,
                    child: Container(
                      width: 100, height: 80,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _localIsDark ? Colors.white12 : Colors.black12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasClass) ...[
                            Text(slot.displayContext, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text(slot.courseCode, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: _localIsDark ? Colors.white : Colors.black)),
                            if (slot.isCancelled) const Text("CANCELLED", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                            if (slot.newRoom != null) Text(slot.newRoom!, style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                          ] else const Text("-", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- Profile Tab ---
  Widget _teacherProfile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCompactHeader(), // Reuse animated header
        const SizedBox(height: 20),
        const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildCompactCard(icon: Icons.edit, title: 'Edit Name', subtitle: 'Update display name', onTap: () {}, index: 0),
        _buildThemeToggle(1),
        _buildCompactCard(icon: Icons.logout, title: 'Log Out', subtitle: 'Sign out', onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage(isDark: _localIsDark, onToggleTheme: widget.onToggleTheme)), (r) => false), index: 2),
      ],
    );
  }

  // --- REUSED WIDGETS (Simplified for this context) ---
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _headerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(profileImage)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teacherName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(teacherEmail, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required int index}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: cs.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeToggle(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.brightness_6, color: Colors.purple)),
        title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_localIsDark ? 'Dark Mode' : 'Light Mode'),
        trailing: Switch(value: _localIsDark, onChanged: (v) { setState(() => _localIsDark = v); widget.onToggleTheme(v); }),
      ),
    );
  }
}

// ====================== COMPONENT WIDGETS ======================

class CabinStatusCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;
  const CabinStatusCard({super.key, required this.isAvailable, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isAvailable ? const LinearGradient(colors: [Color(0xFF27E08D), Color(0xFF118B4A)]) : const LinearGradient(colors: [Color(0xFFEF476F), Color(0xFFD32F2F)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(isAvailable ? Icons.check_circle : Icons.do_not_disturb_on, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Cabin Status", style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              Text(isAvailable ? "Available" : "Not Available", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          ),
          Switch(value: isAvailable, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: Colors.white24),
        ],
      ),
    );
  }
}

class NextClassCard extends StatelessWidget {
  final List<TimetableDay> grid;
  final List<Map<String, String>> slots;
  const NextClassCard({super.key, required this.grid, required this.slots});

  // Helper to find next class based on current time
  TimetableSlot? _findNextClass() {
    if (grid.isEmpty) return null;
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final dayName = days[math.min(now.weekday - 1, 4)];

    // Find today's data
    final todayData = grid.firstWhere((d) => d.dayName == dayName, orElse: () => TimetableDay(dayName: '', slots: []));

    int currentMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < slots.length; i++) {
      int slotStart = _toMinutes(slots[i]['time']!);
      if (slotStart > currentMinutes) {
        if (i < todayData.slots.length && todayData.slots[i].courseCode.isNotEmpty) {
          return todayData.slots[i];
        }
      }
    }
    return null;
  }

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final next = _findNextClass();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B57D0), Color(0xFF0646A6)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(Icons.school, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('UPCOMING CLASS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(next != null ? next.courseName : 'No upcoming classes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              if (next != null) Text('${next.displayContext} • ${next.room}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM PAINTERS FOR PROFILE (From Code A) ---
class _CompactPatternPainter extends CustomPainter {
  final bool isDark;
  _CompactPatternPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 20, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}