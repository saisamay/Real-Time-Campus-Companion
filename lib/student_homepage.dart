// lib/student_homepage.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'find_teacher_page.dart';
import 'find_classroom_page.dart';
import 'student_timetable_page.dart';
import 'main.dart';
import 'profile_page.dart';
import 'emptyclassrooms_page_student.dart';
import 'Events_page.dart';

// Student Home Page Class
class StudentHomePage extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final String? userName;
  final String? userEmail;
  final String? branch;
  final String? section;
  final String? semester;
  final String? profile;

  const StudentHomePage({
    super.key,
    required this.universityName,
    this.isDark = false,
    this.onToggleTheme,
    this.userName,
    this.userEmail,
    this.branch,
    this.section,
    this.semester,
    this.profile,
  });

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage>
    with TickerProviderStateMixin {
  int _index = 0;
  late PageController _pageController;
  late String selectedDept;
  late String selectedSection;
  late String selectedSemester;
  late String userName;
  late String userEmail;
  late bool _isDark;
  late AnimationController _fabController;

  final List<String> eventImages = const [
    'https://picsum.photos/1200/600?random=1',
    'https://picsum.photos/1200/600?random=2',
    'https://picsum.photos/1200/600?random=3',
  ];

  final Map<String, Map<String, List<String>>> timetableData = {
    'EEE': {
      'N302': [
        'https://picsum.photos/800/400?random=11',
        'https://picsum.photos/800/400?random=12',
      ],
    },
    'CSE': {
      'A': ['https://picsum.photos/800/400?random=21'],
    },
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    selectedDept = (widget.branch ?? 'EEE').toUpperCase();
    selectedSection = (widget.section ?? 'A').toUpperCase();
    selectedSemester = (widget.semester ?? '5');
    userName = widget.userName ?? 'Student Name';
    userEmail = widget.userEmail ?? 'student@university.edu';
    _isDark = widget.isDark;

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateUserName(String name) => setState(() => userName = name);
  void _updateUserEmail(String email) => setState(() => userEmail = email);
  void _updateTheme(bool isDark) => setState(() => _isDark = isDark);

  Widget _homePage(BuildContext context) {
    final imagesForPreview =
        timetableData[selectedDept]?[selectedSection] ?? <String>[];
    final String previewImage = imagesForPreview.isNotEmpty
        ? imagesForPreview.first
        : 'https://picsum.photos/800/400?random=21';
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),
        // Enhanced carousel with gradient overlay
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.95,
                    autoPlayInterval: const Duration(seconds: 3),
                  ),
                  items: eventImages.map((url) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(url, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // NEW: Timetable Preview Frame - Scrollable in both directions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  const Color(0xFF1A237E).withOpacity(0.3),
                  const Color(0xFF283593).withOpacity(0.2),
                ]
                    : [
                  const Color(0xFF00BCD4).withOpacity(0.1),
                  const Color(0xFF00ACC1).withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: -3,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Scrollable Timetable Image
                  InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Image.network(previewImage, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  // Top Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withOpacity(0.9),
                            scheme.secondary.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '$selectedDept - $selectedSection',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  // Bottom Info Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Your Timetable',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pinch to zoom • Swipe to scroll',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          FilledButton(
                            onPressed: () => _goToPage(1),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Full View',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Enhanced announcements section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Announcements",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Enhanced announcement cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _buildAnnouncementCard(
                context,
                icon: Icons.campaign,
                title: "Tech Fest this weekend!",
                subtitle: "Don't miss the cultural night.",
                gradient: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
              ),
              const SizedBox(height: 10),
              _buildAnnouncementCard(
                context,
                icon: Icons.book,
                title: "Library open till 10 PM",
                subtitle: "Extended hours for exams.",
                gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAnnouncementCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required List<Color> gradient,
      }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.3),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
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
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.universityName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            key: ValueKey('theme_toggle_$_isDark'),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: Icon(
                _isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                key: ValueKey(_isDark),
              ),
            ),
            onPressed: () {
              setState(() {
                _isDark = !_isDark;
              });
              if (widget.onToggleTheme != null) {
                widget.onToggleTheme!(_isDark);
              }
            },
            tooltip: _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A237E), const Color(0xFF283593)]
                      : [const Color(0xFFA4123F), const Color(0xFFD81B60)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(
                            "https://i.pravatar.cc/150?img=3",
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$selectedDept - $selectedSection',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: "Home",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_search_rounded,
                    title: 'Find Teacher (Cabin/Room)',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FindTeacherPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.search_rounded,
                    title: "Find Friend Class Room",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FindClassRoomPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.schedule_rounded,
                    title: "Timetable",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.event_rounded,
                    title: "Events",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(2);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: "Settings",
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(4);
                    },
                  ),
                  const Divider(height: 20),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginPage(
                            isDark: _isDark,
                            onToggleTheme: widget.onToggleTheme ?? (bool v) {},
                          ),
                        ),
                            (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          _homePage(context),
          const StudentTimetablePage(embedded: true),
          const EventsPage(),
          const EmptyClassroomsPagestudent(),
          ProfilePage(
            userName: userName,
            userEmail: userEmail,
            dept: selectedDept,
            section: selectedSection,
            isDark: _isDark,
            onToggleTheme: (bool isDark) {
              setState(() => _isDark = isDark);
              if (widget.onToggleTheme != null) {
                widget.onToggleTheme!(isDark);
              }
            },
            onUpdateName: _updateUserName,
            onUpdateEmail: _updateUserEmail,
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goToPage,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule_rounded),
              label: 'Timetable',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event_rounded),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room_rounded),
              label: 'Classrooms',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? scheme.error : scheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? scheme.error : scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}