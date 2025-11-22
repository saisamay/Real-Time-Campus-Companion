import 'package:flutter/material.dart';
import 'dart:math' as math; // Required for custom painters
import 'main.dart'; // Ensure this exists for LoginPage
import 'student_timetable_page.dart'; // Ensure this exists
import 'emptyclassrooms_page.dart'; // Ensure this exists

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
    return TeachersHome(
      universityName: universityName,
      isDark: isDark,
      onToggleTheme: onToggleTheme,
      userName: userName,
      userEmail: userEmail,
    );
  }
}

class TeachersHome extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;
  final String userName;
  final String userEmail;

  const TeachersHome({
    super.key,
    required this.universityName,
    required this.isDark,
    required this.onToggleTheme,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<TeachersHome> createState() => _TeachersHomeState();
}

class _TeachersHomeState extends State<TeachersHome>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Profile info
  late String teacherName;
  late String teacherEmail;
  String department = 'CSE';
  String cabin = 'Block A - 305';
  String profileImage = 'https://i.pravatar.cc/150?img=5';

  // Local state
  late bool _localIsDark;
  bool _isAvailable = true;

  // --- ANIMATION CONTROLLERS FOR PROFILE ---
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;
  late Animation<double> _headerScale;
  late Animation<double> _headerFade;
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _cardSlides;

  // Admin-style Color Palette
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

  // Helper for Gradient (Adapts to Dark Mode)
  LinearGradient get _headerGradient => _localIsDark
      ? const LinearGradient(
          // UPDATED: darker grey like screenshot when dark
          colors: [Color(0xFF1F1F1F), Color(0xFF121212)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF0D6EFD), Color(0xFF20C997)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  // Timetable Data
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
    _pageController = PageController(initialPage: _currentIndex);
    teacherName = widget.userName.isNotEmpty ? widget.userName : 'Dr. Sharma';
    teacherEmail = widget.userEmail.isNotEmpty
        ? widget.userEmail
        : 'dr.sharma@university.edu';
    _localIsDark = widget.isDark;
    _calculateInitialAvailability();

    // --- INITIALIZE ANIMATIONS ---
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _headerScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _headerFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeIn));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // We have 6 items in the profile list (Name, Email, Cabin, TT, Theme, Logout)
    _cardSlides = List.generate(6, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(i * 0.1, 0.5 + (i * 0.1), curve: Curves.easeOutCubic),
        ),
      );
    });

    _headerController.forward();
    _cardsController.forward();
  }

  void _calculateInitialAvailability() {
    final now = DateTime.now();
    if (now.weekday > 5) {
      _isAvailable = true;
      return;
    }
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final dayName = weekdays[now.weekday - 1];
    final daySchedule = teacherTimetable[dayName];
    if (daySchedule == null) {
      _isAvailable = true;
      return;
    }

    int currentMinutes = now.hour * 60 + now.minute;
    bool isBusy = false;
    for (var i = 0; i < slots.length; i++) {
      int start = _toMinutes(slots[i]['time']!);
      int end = start + 50;
      if (currentMinutes >= start && currentMinutes < end) {
        final sub = daySchedule[i]['sub'] ?? '';
        if (sub.isNotEmpty && sub != 'Lunch' && sub != 'Research') {
          isBusy = true;
          break;
        }
      }
    }
    _isAvailable = !isBusy;
  }

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return h * 60 + m;
  }

  @override
  void didUpdateWidget(covariant TeachersHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() => _localIsDark = widget.isDark);
    }
  }

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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Trigger entrance animations if going to profile (Index 3)
    if (index == 3) {
      _headerController.reset();
      _cardsController.reset();
      _headerController.forward();
      _cardsController.forward();
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: _headerGradient),
      ),
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 26),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Center(
              child: Text(
                'Teacher Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.brightness_medium,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              setState(() => _localIsDark = !_localIsDark);
              widget.onToggleTheme(_localIsDark);
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Drawer _buildDrawer() {
    Widget menuItem({
      required int index,
      required IconData icon,
      required String label,
    }) {
      final color = _paletteColor(index);
      final tileBg = _currentIndex == index
          ? _paletteColor(index, opacity: _localIsDark ? 0.18 : 0.12)
          : Colors.transparent;
      final iconColor = _localIsDark ? Colors.white : color;
      final textColor = _localIsDark ? Colors.white : Colors.black87;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Container(
              width: 6,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            title: Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            trailing: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _localIsDark
                    ? const Color(0xFF1F1F1F)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _goToPage(index);
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      );
    }

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
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(profileImage),
                ),
                const SizedBox(height: 8),
                Text(
                  teacherName,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Faculty Member',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          menuItem(index: 0, icon: Icons.home, label: 'Home'),
          menuItem(index: 2, icon: Icons.meeting_room, label: 'Classrooms'),
          menuItem(index: 3, icon: Icons.person, label: 'Profile'),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      isDark: _localIsDark,
                      onToggleTheme: widget.onToggleTheme,
                    ),
                  ),
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: _localIsDark
                      ? Colors.red.withOpacity(0.08)
                      : Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Container(
                    width: 6,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: _localIsDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _localIsDark
                          ? const Color(0xFF1F1F1F)
                          : Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: _localIsDark ? Colors.white : Colors.redAccent,
                      size: 18,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
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
      // NEW: dark background like screenshot when in dark mode
      backgroundColor: _localIsDark
          ? const Color(0xFF121212)
          : Theme.of(context).scaffoldBackgroundColor,
      // ================= REPLACED AnimatedSwitcher WITH PageView =================
      body: PageView(
        controller: _pageController,
        // Update current index when user swipes
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _buildHome(),
          const StudentTimetablePage(embedded: true),
          EmptyClassroomsPage(userBranch: department, userSection: 'A'),
          _teacherProfile(context),
        ],
      ),
      // ==========================================================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _localIsDark
              ? Colors.grey.shade900.withOpacity(0.92)
              : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (i) => _goToPage(i),
          selectedItemColor: _localIsDark ? Colors.white : Colors.black87,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          showSelectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month, size: 24),
              label: 'Student TT',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room, size: 24),
              label: 'Classrooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: _headerGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: const Icon(
                      Icons.school,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          teacherName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$department • $cabin',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CabinStatusCard(
                  isAvailable: _isAvailable,
                  onChanged: (val) {
                    setState(() => _isAvailable = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'Marked Available' : 'Marked Busy'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                NextClassCard(timetable: teacherTimetable, slots: slots),
                const SizedBox(height: 24),
                Text(
                  'Weekly Timetable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _paletteColor(0).withOpacity(0.2),
                            child: Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: _paletteColor(0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Weekly Timetable',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TeacherTimetableWidget(
                        timetable: teacherTimetable,
                        slots: slots,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================== NEW ANIMATED PROFILE UI ========================

  Widget _buildCompactHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _headerFade,
      child: ScaleTransition(
        scale: _headerScale,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A237E).withOpacity(0.95),
                      const Color(0xFF283593).withOpacity(0.9),
                    ]
                  : [
                      const Color(0xFF0D6EFD).withOpacity(0.95),
                      const Color(0xFF20C997).withOpacity(0.9),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.indigo : Colors.blueAccent).withOpacity(
                  0.4,
                ),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CompactPatternPainter(isDark: isDark),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 2000),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return CustomPaint(
                                size: const Size(85, 85),
                                painter: _CompactRingPainter(
                                  progress: value,
                                  isDark: isDark,
                                ),
                              );
                            },
                          ),
                          Hero(
                            tag: 'profile_image',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundImage: NetworkImage(profileImage),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  profileImage =
                                      'https://images.unsplash.com/photo-1525973132219-a04334a76080?auto=format&fit=crop&w=800&q=80';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile photo updated'),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacherName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black26,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '$department - $cabin',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.email_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      teacherEmail,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int index,
    List<Color>? gradientColors,
  }) {
    final cs = Theme.of(context).colorScheme;
    final gradient = gradientColors ?? [cs.primary, cs.secondary];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(_cardSlides[index]),
      child: FadeTransition(
        opacity: _cardSlides[index],
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.08),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // UPDATED: icon style like screenshot
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: gradient.first.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: gradient.first,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(int index) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(_cardSlides[index]),
      child: FadeTransition(
        opacity: _cardSlides[index],
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // UPDATED: icon style like screenshot
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _localIsDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _localIsDark ? 'Dark mode active' : 'Light mode active',
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
                    widget.onToggleTheme(value);
                  },
                  activeColor: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teacherProfile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 8),
        _buildCompactHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [cs.primary, cs.secondary],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildCompactCard(
                icon: Icons.edit,
                title: 'Edit Name',
                subtitle: 'Update your display name',
                onTap: () => _showEditDialog(
                  'Edit Name',
                  teacherName,
                  (v) => setState(() => teacherName = v),
                ),
                index: 0,
                gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              _buildCompactCard(
                icon: Icons.email_rounded,
                title: 'Edit Email',
                subtitle: 'Change your email address',
                onTap: () => _showEditDialog(
                  'Edit Email',
                  teacherEmail,
                  (v) => setState(() => teacherEmail = v),
                ),
                index: 1,
                gradientColors: const [Color(0xFFF093FB), Color(0xFFF5576C)],
              ),
              _buildCompactCard(
                icon: Icons.home_work,
                title: 'Edit Cabin',
                subtitle: 'Update office location',
                onTap: () => _showEditDialog(
                  'Edit Cabin',
                  cabin,
                  (v) => setState(() => cabin = v),
                ),
                index: 2,
                gradientColors: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
              ),
              _buildCompactCard(
                icon: Icons.event,
                title: 'Edit Timetable',
                subtitle: 'Manage your class schedule',
                onTap: () async {
                  await _openTimetableEditor(context);
                },
                index: 3,
                gradientColors: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              ),
              _buildThemeToggle(4),
              _buildCompactCard(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                subtitle: 'Sign out from your account',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => LoginPage(
                        isDark: _localIsDark,
                        onToggleTheme: widget.onToggleTheme,
                      ),
                    ),
                    (route) => false,
                  );
                },
                index: 5,
                gradientColors: const [Color(0xFFFA709A), Color(0xFFFEE140)],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Helper Methods for Profile Actions ---
  void _showEditDialog(
    String title,
    String initial,
    ValueChanged<String> onSave,
  ) {
    final ctrl = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) onSave(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTimetableEditor(BuildContext context) async {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    String selectedDay = days.first;
    int selectedSlot = 0;
    final subjectCtrl = TextEditingController();
    final roomCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(bCtx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Edit Timetable',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (ctx, setStateSB) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          border: OutlineInputBorder(),
                        ),
                        items: days
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setStateSB(() => selectedDay = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedSlot,
                        decoration: const InputDecoration(
                          labelText: 'Slot (index starts 0)',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(
                          slots.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text('${i + 1} — ${slots[i]['time']}'),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) setStateSB(() => selectedSlot = v);
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(bCtx);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Save'),
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
}

// --- CUSTOM PAINTERS FOR PROFILE ---

// Compact ring painter
class _CompactRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _CompactRingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius, outerPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
      colors: isDark
          ? [
              Colors.white,
              const Color(0xFF64B5F6),
              Colors.white.withOpacity(0.1),
            ]
          : [
              Colors.white,
              const Color(0xFF26C6DA),
              Colors.white.withOpacity(0.1),
            ],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(_CompactRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Compact pattern painter
class _CompactPatternPainter extends CustomPainter {
  final bool isDark;

  _CompactPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.2 + i * 0.2);
      final y = size.height * 0.3;
      final radius = 30.0 - (i * 5);
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }

    // Diagonal lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 6; i++) {
      final x = i * (size.width / 6);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.5, size.height),
        linePaint,
      );
    }

    // Dots pattern
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 15; i++) {
      for (var j = 0; j < 6; j++) {
        if ((i + j) % 2 == 0) {
          final x = i * (size.width / 15) + 5;
          final y = j * (size.height / 6) + 5;
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    }

    // Curved waves
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.6);

    for (var i = 0; i <= 4; i++) {
      final x = (size.width / 4) * i;
      final y = size.height * 0.6 + (i.isEven ? -15 : 15);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = (size.width / 4) * (i - 1);
        final prevY = size.height * 0.6 + ((i - 1).isEven ? -15 : 15);
        final controlX = (prevX + x) / 2;
        final controlY = (prevY + y) / 2;
        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }

    canvas.drawPath(path, wavePaint);

    // Radial gradient overlay
    final radialPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.5),
        radius: 1.2,
        colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), radialPaint);
  }

  @override
  bool shouldRepaint(_CompactPatternPainter oldDelegate) => false;
}

// ====================== 1. CABIN STATUS CARD ======================
class CabinStatusCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const CabinStatusCard({
    super.key,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAvailable
        ? const Color(0xFF20C997)
        : const Color(0xFFEF476F);
    final text = isAvailable ? "Available" : "Not Available";
    final icon = isAvailable ? Icons.check_circle : Icons.do_not_disturb_on;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isAvailable
            ? const LinearGradient(
                colors: [Color(0xFF27E08D), Color(0xFF118B4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFEF476F), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cabin Status",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white24,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}

// ====================== 2. NEXT CLASS CARD ======================
class NextClassCard extends StatelessWidget {
  final Map<String, List<Map<String, String>>> timetable;
  final List<Map<String, String>> slots;

  const NextClassCard({
    super.key,
    required this.timetable,
    required this.slots,
  });

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
    return slots.length;
  }

  Map<String, String>? _findNextClass() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final now = DateTime.now();
    final todayIndex = (now.weekday - 1) % 7;
    final effectiveTodayIndex = (now.weekday > 5) ? 0 : todayIndex;
    final startSearchSlot = (now.weekday > 5) ? 0 : _currentSlotIndex();

    for (int d = 0; d < 7; d++) {
      final di = (effectiveTodayIndex + d) % weekdays.length;
      final day = weekdays[di];
      final cells = timetable[day] ?? [];
      final startSlot = d == 0 ? startSearchSlot : 0;

      for (int s = startSlot; s < cells.length && s < slots.length; s++) {
        final c = cells[s];
        final sub = (c['sub'] ?? '').trim();
        if (sub.isNotEmpty && sub != 'Lunch' && sub != 'Research') {
          return {
            'day': d == 0 ? 'Today' : day,
            'time': slots[s]['time'] ?? '',
            'sub': sub,
            'room': c['room'] ?? '',
          };
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final next = _findNextClass();
    final hasNext = next != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B57D0), Color(0xFF0646A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPCOMING CLASS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                if (hasNext) ...[
                  Text(
                    next!['sub']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${next['day']} at ${next['time']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.room,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Room ${next['room']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Text(
                    'No upcoming classes found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherTimetableWidget extends StatelessWidget {
  final Map<String, List<Map<String, String>>> timetable;
  final List<Map<String, String>> slots;

  const TeacherTimetableWidget({
    super.key,
    required this.timetable,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    const slotWidth = 90.0;

    // 1. Determine if Dark Mode is active
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ TIME COLUMN (Left) ============
            Column(
              children: [
                Container(
                  width: slotWidth,
                  height: 48,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...List.generate(slots.length, (i) {
                  // -------------------------
                  // TIME COLUMN BG COLOR LOGIC
                  // -------------------------
                  final Color timeBgColor = isDark
                      ? const Color(0xFF252525) // Dark Mode: Dark Grey
                      : Colors.white; // Light Mode: White

                  final Color timeTextColor = isDark
                      ? Colors
                            .white // Dark Mode: White Text
                      : Colors.black87; // Light Mode: Black Text

                  return Container(
                    width: slotWidth,
                    height: 64,
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 6,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(6),
                      color: timeBgColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '(${slots[i]['no']})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: timeTextColor.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slots[i]['time']!,
                          style: TextStyle(fontSize: 12, color: timeTextColor),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

            // ============ WEEKDAY COLUMNS ============
            ...weekdays.map((day) {
              final cells = (timetable[day] ?? [])
                  .followedBy(
                    List.generate(
                      9,
                      (_) => {'sub': '', 'room': '', 'section': ''},
                    ),
                  )
                  .take(9)
                  .toList();
              return Column(
                children: [
                  Container(
                    width: 150,
                    height: 48,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...List.generate(slots.length, (i) {
                    final c = cells[i];
                    final hasClass = (c['sub'] ?? '').isNotEmpty;

                    // ------------------------------------
                    // MAIN GRID COLOR LOGIC (UPDATED)
                    // ------------------------------------
                    Color bgColor;
                    if (hasClass) {
                      // Occupied Slot: Blue
                      bgColor = isDark
                          ? const Color(0xFF1565C0).withOpacity(
                              0.5,
                            ) // Dark: Translucent Blue
                          : const Color(0xFF64B5F6); // Light: Solid Blue 300
                    } else {
                      // Empty Slot
                      bgColor = isDark
                          ? const Color(0xFF252525) // Dark: Dark Grey
                          : Colors.white; // Light: White
                    }

                    // Text Color Logic: Inverts based on theme
                    final Color titleColor = isDark
                        ? Colors.white
                        : Colors.black87;

                    final Color subTitleColor = isDark
                        ? Colors.white70
                        : Colors.black54;

                    return Container(
                      width: 150,
                      height: 64,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                        color: bgColor, // Applied specific color
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['sub'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c['room'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: subTitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
