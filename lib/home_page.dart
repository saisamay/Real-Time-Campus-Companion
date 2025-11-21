import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'find_teacher_page.dart';
import 'find_classroom_page.dart';
import 'student_timetable_page.dart'; // ✅ Using the smart timetable page
import 'main.dart';
import 'profile_page.dart';
import 'emptyclassrooms_page_student.dart';
import 'Events_page.dart';

class HomePage extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final String? userName;
  final String? userEmail;
  final String? branch;
  final String? section;

  // ✅ FIXED: Changed int to String to match backend "S5"
  final String? semester;

  final String? profile;

  const HomePage({
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
  State<HomePage> createState() => _CrHomePageState();
}

class _CrHomePageState extends State<HomePage> {
  int _index = 0;
  late PageController _pageController;

  // selections
  late String selectedBranch;
  late String selectedSection;
  late String selectedSemester;

  // User state
  late String userName;
  late String userEmail;

  // Images for Home Page Carousel
  final List<String> eventImages = const [
    'https://picsum.photos/1200/600?random=1',
    'https://picsum.photos/1200/600?random=2',
    'https://picsum.photos/1200/600?random=3',
  ];

  // Timetable Preview Data
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

    // Initialize from widget
    selectedBranch = (widget.branch ?? 'EEE').toUpperCase();
    selectedSection = (widget.section ?? 'A').toUpperCase();
    // ✅ Handle String semester
    selectedSemester = widget.semester ?? 'S5';

    userName = widget.userName ?? 'Class Rep';
    userEmail = widget.userEmail ?? 'cr@university.edu';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut
    );
  }

  // ✅ HELPER: Logic to decide if image is Network, File, or Asset
  ImageProvider _getProfileProvider() {
    final String? path = widget.profile;

    if (path == null || path.isEmpty) {
      return const AssetImage('assets/default_avatar.png');
    }

    if (path.startsWith('http')) {
      return NetworkImage(path);
    }

    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (e) {
      // Ignore error
    }

    return const AssetImage('assets/default_avatar.png');
  }

  // ---------- HOME PAGE CONTENT ----------
  Widget _homePage(BuildContext context) {
    final imagesForPreview = timetableData[selectedBranch]?[selectedSection] ?? <String>[];
    final previewImage = imagesForPreview.isNotEmpty ? imagesForPreview.first : null;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),

        // ✅ Added CR Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A3F8A), Color(0xFF8A63D2)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Class Representative", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("You can manage timetable slots.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Events carousel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 180,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.95,
                autoPlayInterval: const Duration(seconds: 3),
              ),
              items: eventImages.map((url) {
                return Image.network(url, fit: BoxFit.cover, width: double.infinity);
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Timetable preview card
        if (previewImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 200, width: double.infinity, child: Image.network(previewImage, fit: BoxFit.cover)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$selectedBranch - $selectedSection',
                            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _goToPage(1),
                          icon: const Icon(Icons.edit_calendar), // CR specific icon
                          label: const Text('Manage Timetable'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text("Announcements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const ListTile(
          leading: Icon(Icons.campaign),
          title: Text("Tech Fest this weekend!"),
          subtitle: Text("Don't miss the cultural night."),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------- BUILD METHOD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.universityName} (CR)"), // Show CR in title
        leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _openQuickSearch(context)),
          const SizedBox(width: 8),
        ],
      ),

      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple), // Distinct color for CR
            currentAccountPicture: CircleAvatar(
              backgroundImage: _getProfileProvider(),
              backgroundColor: Colors.white24,
            ),
            accountName: Text(userName),
            accountEmail: Text(userEmail),
          ),
          ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () {
            Navigator.pop(context);
            _goToPage(0);
          }),
          // CR Specific Label
          ListTile(leading: const Icon(Icons.edit_calendar), title: const Text("Manage Timetable"), onTap: () {
            Navigator.pop(context);
            _goToPage(1);
          }),
          ListTile(leading: const Icon(Icons.event), title: const Text("Events"), onTap: () {
            Navigator.pop(context);
            _goToPage(2);
          }),
          ListTile(leading: const Icon(Icons.person_search), title: const Text('Find Teacher'), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FindTeacherPage()));
          }),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              _goToPage(4);
            },
          ),

          ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: () {
            Navigator.pop(context);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => LoginPage(
                  isDark: widget.isDark,
                  onToggleTheme: widget.onToggleTheme ?? (bool v) {},
                ),
              ),
                  (Route<dynamic> route) => false,
            );
          }),
        ]),
      ),

      body: PageView(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _index = i),
          children: [
            _homePage(context),

            // ✅ THIS IS THE KEY: Using StudentTimetablePage
            // It will detect 'classrep' role and show Edit buttons automatically
            const StudentTimetablePage(embedded: true),

            const EventsPage(),
            const EmptyClassroomsPage(),

            ProfilePage(
              userName: userName,
              userEmail: userEmail,
              dept: selectedBranch,
              section: selectedSection,
              isDark: widget.isDark,
              onToggleTheme: widget.onToggleTheme ?? (_) {},
              initialPhotoUrl: widget.profile ?? '',
            ),
          ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.edit_calendar), label: 'Timetable'), // Distinct icon
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bCtx) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(bCtx).viewInsets.bottom + 16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search anything…', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onSubmitted: (q) {
              Navigator.pop(bCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Searching for: $q')));
            },
          ),
        );
      },
    );
  }
}