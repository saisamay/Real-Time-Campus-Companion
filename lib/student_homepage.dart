// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'find_teacher_page.dart';
import 'find_classroom_page.dart';
import 'timetable_page.dart';
import 'main.dart'; // for LoginPage navigation
import 'profile_page.dart'; // NEW
import 'emptyclassrooms_page_student.dart'; // NEW

class StudentHomePage extends StatefulWidget {
  final String universityName;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final String? userName;
  final String? userEmail;
  final String? branch;
  final String? section;
  final String? semester;

  const StudentHomePage({
    super.key,
    required this.universityName,
    this.isDark = false, // default
    this.onToggleTheme, // optional
    this.userName,
    this.userEmail,
    this.branch,
    this.section,
    this.semester,
  });

  @override
  State<StudentHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<StudentHomePage> {
  int _index = 0;
  late PageController _pageController;

  // single set of selected values (initialized in initState)
  late String selectedDept;
  late String selectedSection;
  late String selectedSemester;

  // User state (can be populated from AuthService later)
  late String userName;
  late String userEmail;

  // Images and sample data (kept from your design)
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

    // initialize from widget, with sensible defaults
    selectedDept = (widget.branch ?? 'EEE').toUpperCase();
    selectedSection = (widget.section ?? 'A').toUpperCase();
    selectedSemester = (widget.semester ?? 'S5').toUpperCase();

    userName = widget.userName ?? 'Student Name';
    userEmail = widget.userEmail ?? 'student@university.edu';
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

  // Allow ProfilePage to update name/email
  void _updateUserName(String name) => setState(() => userName = name);
  void _updateUserEmail(String email) => setState(() => userEmail = email);

  // ---------- HOME PAGE CONTENT ----------
  Widget _homePage(BuildContext context) {
    final imagesForPreview = timetableData[selectedDept]?[selectedSection] ?? <String>[];
    final previewImage = imagesForPreview.isNotEmpty ? imagesForPreview.first : null;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),
        // Events carousel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200,
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
                  SizedBox(height: 220, width: double.infinity, child: Image.network(previewImage, fit: BoxFit.cover)),
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
                            '$selectedDept - $selectedSection',
                            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
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
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------- EVENTS ----------
  Widget _eventsPage(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        CarouselSlider(
          options: CarouselOptions(
            height: 220.0,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            autoPlayInterval: const Duration(seconds: 3),
          ),
          items: eventImages
              .map((url) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, fit: BoxFit.cover, width: double.infinity)))
              .toList(),
        ),
        const SizedBox(height: 20),
        const Text("Upcoming Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Join our Annual Tech Fest and Cultural Week starting this Friday!", textAlign: TextAlign.center),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: ListView(padding: EdgeInsets.zero, children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFA4123F)),
            currentAccountPicture: const CircleAvatar(backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3")),
            accountName: Text(userName),
            accountEmail: Text(userEmail),
          ),
          ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () {
            Navigator.pop(context);
            _goToPage(0);
          }),
          ListTile(leading: const Icon(Icons.person_search), title: const Text('Find Teacher (Cabin/Room)'), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FindTeacherPage()));
          }),
          ListTile(leading: const Icon(Icons.search), title: const Text("Find Friend Class Room"), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FindClassRoomPage()));
          }),
          ListTile(leading: const Icon(Icons.schedule), title: const Text("Timetable"), onTap: () {
            Navigator.pop(context);
            _goToPage(1);
          }),
          ListTile(leading: const Icon(Icons.event), title: const Text("Events"), onTap: () {
            Navigator.pop(context);
            _goToPage(2);
          }),
          ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.logout), title: const Text("Logout"), onTap: () {
            Navigator.pop(context);
            // navigate to LoginPage (keeps your prior pattern)
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

      body: PageView(controller: _pageController, onPageChanged: (i) => setState(() => _index = i), children: [
        _homePage(context), // 0
        const TimetablePage(embedded: true), // 1
        _eventsPage(context), // 2
        const EmptyClassroomsPage(), // 3 -> external file
        ProfilePage(
          userName: userName,
          userEmail: userEmail,
          dept: selectedDept,
          section: selectedSection,
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          onUpdateName: _updateUserName,
          onUpdateEmail: _updateUserEmail,
        ), // 4
      ]),

      bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: _goToPage, destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.schedule), label: 'Timetable'),
        NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
        NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Classrooms'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ]),
    );
  }

  void _openQuickSearch(BuildContext ctx) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (bCtx) {
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
    });
  }
}
