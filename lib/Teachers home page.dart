import 'package:flutter/material.dart';

class TeacherHomePage extends StatefulWidget {
  final String universityName;
  final String? userName;

  const TeacherHomePage({super.key, required this.universityName, this.userName});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;

  // Sample timetable for "today". In a real app you'll fetch this from backend.
  final List<ClassSlot> _todaySlots = [
    ClassSlot(start: '08:30', end: '09:20', title: 'CSE-B - Data Structures', room: 'N106'),
    ClassSlot(start: '09:30', end: '10:20', title: 'CSE-B - Algorithms', room: 'N106'),
    ClassSlot(start: '10:30', end: '11:20', title: 'CSE-B - DBMS', room: 'N201'),
    ClassSlot(start: '13:00', end: '13:50', title: 'CSE-B - Operating Systems', room: 'N106'),
    ClassSlot(start: '14:00', end: '14:50', title: 'CSE-B - Lab', room: 'Lab-3'),
  ];

  @override
  Widget build(BuildContext context) {
    final next = _findNextClass(_todaySlots);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white,
            child: Row(
              children: [
                // Left: search
                IconButton(
                  onPressed: () {
                    // implement search action
                    showSearch(context: context, delegate: _DummySearch());
                  },
                  icon: const Icon(Icons.search),
                ),

                // Middle: university name (expanded)
                Expanded(
                  child: Center(
                    child: Text(
                      widget.universityName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Right: menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // handle menu selections
                    switch (value) {
                      case 'profile':
                        _onNavTap(2);
                        break;
                      case 'settings':
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings')));
                        break;
                      case 'logout':
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'profile', child: Text('Profile')),
                    PopupMenuItem(value: 'settings', child: Text('Settings')),
                    PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // Greeting and user
          Container(
            width: double.infinity,
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Welcome${widget.userName != null ? ', ${widget.userName}' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Timetable
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today\'s Timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _todaySlots.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final s = _todaySlots[idx];
                            final isNext = next != null && next == s;
                            return _buildSlotCard(s, isNext);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Next class summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: const Text('Next Class', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: next != null
                    ? Text('${next.title} • ${next.room} • ${next.start} - ${next.end}')
                    : const Text('No more classes for today'),
                leading: const Icon(Icons.schedule),
                trailing: next != null ? ElevatedButton(onPressed: () {}, child: const Text('Go')) : null,
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Classroom'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSlotCard(ClassSlot s, bool highlight) {
    return Card(
      color: highlight ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${s.room} • ${s.start} - ${s.end}'),
        trailing: highlight ? const Chip(label: Text('Upcoming')) : null,
      ),
    );
  }

  void _onNavTap(int idx) {
    setState(() => _selectedIndex = idx);
    // handle the navigation change - for demo we only show a snackbar or would navigate to real pages
    switch (idx) {
      case 0:
      // already home
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open classroom list')));
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open profile')));
        break;
    }
  }

  // Find the first class whose end time is after now
  ClassSlot? _findNextClass(List<ClassSlot> slots) {
    final now = DateTime.now();
    for (final s in slots) {
      final end = _timeToday(s.end);
      final start = _timeToday(s.start);
      if (end.isAfter(now) || (start.isBefore(now) && end.isAfter(now))) {
        return s;
      }
    }
    return null;
  }

  DateTime _timeToday(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }
}

class ClassSlot {
  final String start;
  final String end;
  final String title;
  final String room;

  ClassSlot({required this.start, required this.end, required this.title, required this.room});
}

// A tiny search delegate used by the search icon (placeholder)
class _DummySearch extends SearchDelegate<String> {
  final suggestions = ['CSE-B', 'N106', 'DBMS', 'Algorithms'];

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => Center(child: Text('Searched: $query'));

  @override
  Widget buildSuggestions(BuildContext context) {
    final list = query.isEmpty ? suggestions : suggestions.where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) => ListTile(
        title: Text(list[idx]),
        onTap: () {
          query = list[idx];
          showResults(context);
        },
      ),
    );
  }
}
