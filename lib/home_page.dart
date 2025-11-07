// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'find_teacher_page.dart';
// import the new page
import 'find_classroom_page.dart';

class HomePage extends StatefulWidget {
  final String universityName;

  const HomePage({super.key, required this.universityName, required userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // make this const since it's static
  final List<String> eventImages = const [
    'https://picsum.photos/800/400?random=1',
    'https://picsum.photos/800/400?random=2',
    'https://picsum.photos/800/400?random=3',
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.universityName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open navigation drawer',
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(radius: 14, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3")),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile clicked"))),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          // <-- removed const here because NetworkImage is non-const
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFA4123F)),
            currentAccountPicture: const CircleAvatar(backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3")),
            accountName: const Text("Student Name"),
            accountEmail: const Text("student@university.edu"),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_search),
            title: const Text('Find Teacher (Cabin/Room)'),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindTeacherPage()),
              );
            },
          ),

          // NEW: Find Friend Class Room item
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text("Find Friend Class Room"),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindClassRoomPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text("Timetable"),
            onTap: () {
              Navigator.pop(context);
              // TODO: navigate to own timetable page
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Events"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => Navigator.pop(context),
          ),
        ]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CarouselSlider.builder(
                  itemCount: eventImages.length,
                  itemBuilder: (context, itemIndex, realIndex) {
                    final url = eventImages[itemIndex];
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 48),
                          );
                        },
                        semanticLabel: 'Event image ${itemIndex + 1}',
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.95,
                    autoPlayInterval: const Duration(seconds: 3),
                    onPageChanged: (index, reason) => setState(() => _currentIndex = index),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: eventImages.asMap().entries.map((entry) {
              final idx = entry.key;
              return Container(
                width: _currentIndex == idx ? 12.0 : 8.0,
                height: _currentIndex == idx ? 12.0 : 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == idx ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(alignment: Alignment.centerLeft, child: Text("Upcoming Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(children: [
                Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: const Icon(Icons.mic), title: const Text('Guest Lecture: Flutter & Beyond'), subtitle: const Text('Nov 10 • 4:00 PM • Auditorium'), onTap: () {})),
                const SizedBox(height: 8),
                Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: const Icon(Icons.sports_score), title: const Text('Inter-University Sports Meet'), subtitle: const Text('Nov 14 • 9:00 AM • Sports Complex'), onTap: () {})),
              ]),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
