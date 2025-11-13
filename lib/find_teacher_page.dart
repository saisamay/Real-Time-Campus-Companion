import 'package:flutter/material.dart';

class TeacherLocationResult {
  final String id; // e.g. "T1001"
  final String teacherName;
  final String department;
  final String cabinNo;
  final String status;
  final String? currentRoom;
  final Map<String, List<String>> timetable;

  TeacherLocationResult({
    required this.id,
    required this.teacherName,
    required this.department,
    required this.cabinNo,
    required this.status,
    this.currentRoom,
    this.timetable = const {},
  });
}

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;

  // now we store a list and also build a small lookup map for exact keys
  final List<TeacherLocationResult> _teachers = [
    TeacherLocationResult(
      id: 'T1001',
      teacherName: 'Dr. Smith',
      department: 'Computer Science',
      cabinNo: 'C-201',
      status: 'In Lecture: Artificial Intelligence',
      currentRoom: 'Room 404, Block B',
      timetable: {
        'Monday': ['10:00 AM - CSE-A (AI)', '02:00 PM - CSE-B (AI Lab)'],
        'Tuesday': ['11:00 AM - Free', '03:00 PM - Free'],
        'Wednesday': ['11:00 AM - CSE-A (AI)'],
        'Thursday': ['10:00 AM - Free'],
        'Friday': ['09:00 AM - Project Mentoring', '01:00 PM - Free'],
      },
    ),
    TeacherLocationResult(
      id: 'T1002',
      teacherName: 'Prof. Elara',
      department: 'Electronics',
      cabinNo: 'E-105',
      status: 'In Cabin',
      currentRoom: null,
      timetable: {
        'Monday': ['10:00 AM - Free', '02:00 PM - Free'],
        'Tuesday': ['09:00 AM - ECE-A (Signals)', '11:00 AM - ECE-B (Lab)'],
        'Wednesday': ['09:00 AM - Free'],
        'Thursday': ['10:00 AM - ECE-A (Signals)'],
        'Friday': ['11:00 AM - Free'],
      },
    ),
    // add more teachers here...
  ];

  // results list (empty = none found)
  List<TeacherLocationResult> _results = [];

  /// Quick exact lookup map (lowercased): keys are id, name, cabin
  late final Map<String, TeacherLocationResult> _exactIndex = {
    for (final t in _teachers) ...{
      t.id.toLowerCase(): t,
      t.teacherName.toLowerCase(): t,
      t.cabinNo.toLowerCase(): t,
    }
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _findTeacher() async {
    final raw = _searchController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a teacher name, id or room no.')));
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
    });

    // small simulated delay (keeps UX consistent)
    await Future.delayed(const Duration(milliseconds: 300));

    final query = raw.toLowerCase();

    // 1) fast exact lookup (id/name/cabin)
    final exact = _exactIndex[query];
    if (exact != null) {
      setState(() {
        _loading = false;
        _results = [exact];
      });
      return;
    }

    // 2) otherwise do partial search across multiple fields (name, id, cabin, dept, status, timetable)
    final List<TeacherLocationResult> found = [];
    final seen = <String>{};
    for (final t in _teachers) {
      final name = t.teacherName.toLowerCase();
      final id = t.id.toLowerCase();
      final cabin = t.cabinNo.toLowerCase();
      final dept = t.department.toLowerCase();
      final status = t.status.toLowerCase();
      final timetableText = t.timetable.values.expand((l) => l).join(' ').toLowerCase();

      if (name.contains(query) ||
          id.contains(query) ||
          cabin.contains(query) ||
          dept.contains(query) ||
          status.contains(query) ||
          timetableText.contains(query)) {
        final key = '${t.id}-${t.cabinNo}';
        if (!seen.contains(key)) {
          seen.add(key);
          found.add(t);
        }
      }
    }

    setState(() {
      _loading = false;
      _results = found;
    });

    if (found.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No matches for '$raw'.")));
    }
  }

  void _showTimetable(BuildContext context, TeacherLocationResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${result.teacherName}'s Timetable"),
        content: SizedBox(
          width: double.maxFinite,
          child: result.timetable.isEmpty
              ? const Text('No schedule available.')
              : ListView(
            shrinkWrap: true,
            children: result.timetable.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...entry.value.map((e) => Text('• $e')),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _showFreePeriods(BuildContext context, TeacherLocationResult result) {
    final Map<String, List<String>> freeSlots = {};
    result.timetable.forEach((day, periods) {
      final freePeriods = periods.where((p) => p.toLowerCase().contains('free')).toList();
      if (freePeriods.isNotEmpty) {
        freeSlots[day] = freePeriods;
      }
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Free Periods — ${result.teacherName}"),
        content: SizedBox(
          width: double.maxFinite,
          child: freeSlots.isEmpty
              ? const Text('No free periods found in the schedule.')
              : ListView(
            shrinkWrap: true,
            children: freeSlots.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...entry.value.map((e) => Text('• $e')),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.grey[700]),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
    ],
  );

  Widget _buildResultCard(TeacherLocationResult res) {
    final String locationText = res.currentRoom ?? res.cabinNo;
    final IconData locationIcon = res.currentRoom != null ? Icons.school : Icons.meeting_room;
    final String locationLabel = res.currentRoom != null ? 'Classroom:' : 'Cabin No:';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(res.teacherName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('${res.department} • ID: ${res.id}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            Icon(locationIcon, color: Colors.grey[700]),
          ]),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, '$locationLabel $locationText'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.info_outline, 'Status: ${res.status}'),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => _showFreePeriods(context, res), child: const Text('Show Free Periods')),
            const SizedBox(width: 8),
            TextButton(onPressed: () => _showTimetable(context, res), child: const Text('View Timetable')),
          ]),
        ]),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24.0),
        child: Center(child: Text('No results — try searching by name, id or cabin no.')),
      );
    }

    return Column(
      children: _results.map((t) => _buildResultCard(t)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Teacher')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name, id, or room (e.g. "Dr. Smith", "T1001", "E-105")',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _findTeacher(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: _loading ? const SizedBox.shrink() : const Icon(Icons.search),
              label: _loading ? const Text('Searching...') : const Text('Find'),
              onPressed: _loading ? null : _findTeacher,
            ),
            const SizedBox(height: 24),
            _buildResultsList(),
          ]),
        ),
      ),
    );
  }
}
