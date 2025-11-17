// lib/find_teacher_page.dart
import 'package:flutter/material.dart';

/// Model for teacher lookup result
class TeacherLocationResult {
  final String teacherName;
  final String dept;
  final bool isTeaching; // true => classroom; false => in cabin
  final String location; // e.g., 'Room 402' or 'Cabin 12'
  final String status; // short status like "Teaching: X" or "In cabin"
  final Map<String, List<String>> timetable;

  TeacherLocationResult({
    required this.teacherName,
    required this.dept,
    required this.isTeaching,
    required this.location,
    required this.status,
    required this.timetable,
  });
}

/// Page to find a teacher's current location (cabin or classroom) and view their timetable.
class FindTeacherPage extends StatefulWidget {
  const FindTeacherPage({super.key});

  @override
  State<FindTeacherPage> createState() => _FindTeacherPageState();
}

class _FindTeacherPageState extends State<FindTeacherPage> {
  final List<String> departments = <String>[
    'Select Department',
    'CSE',
    'ECE',
    'ME',
    'CE',
    'EE',
    'Maths',
    'Physics',
  ];

  final List<String> batches = <String>[
    'Select Batch',
    'All', // means any batch / check cabin status too
    'Sem 1 - CSE',
    'Sem 3 - CSE',
    'Sem 5 - ECE',
    'Sem 2 - ME',
  ];

  String selectedDept = 'Select Department';
  String selectedBatch = 'Select Batch';
  final TextEditingController teacherController = TextEditingController();

  bool _loading = false;
  TeacherLocationResult? _result;

  // ----- MOCK DATABASE -----
  // Key rules (for mock): teacherLower|dept|batch
  final Map<String, TeacherLocationResult> _mockDb = {
    'dr.smith|cse|sem 3 - cse': TeacherLocationResult(
      teacherName: 'Dr. Smith',
      dept: 'CSE',
      isTeaching: true,
      location: 'Room 402, Block A',
      status: 'Teaching: Compiler Design',
      timetable: {
        'Mon': ['09:00 - Compiler Design'],
        'Tue': ['11:00 - Compiler Design'],
        'Thu': ['02:00 - Research Meeting'],
      },
    ),
    'dr.smith|cse|all': TeacherLocationResult(
      teacherName: 'Dr. Smith',
      dept: 'CSE',
      isTeaching: false,
      location: 'Cabin 12, Dept. CSE',
      status: 'In cabin (office hours)',
      timetable: {
        'Mon': ['09:00 - Compiler Design'],
        'Tue': ['11:00 - Compiler Design'],
        'Thu': ['02:00 - Research Meeting'],
      },
    ),
    'prof.jones|ece|sem 5 - ece': TeacherLocationResult(
      teacherName: 'Prof. Jones',
      dept: 'ECE',
      isTeaching: true,
      location: 'Electronics Lab 2',
      status: 'Practical: Analog Lab',
      timetable: {
        'Mon': ['10:00 - Analog Lab'],
        'Wed': ['09:00 - Signal Processing'],
        'Fri': ['11:00 - Microelectronics'],
      },
    ),
    'prof.lee|maths|all': TeacherLocationResult(
      teacherName: 'Prof. Lee',
      dept: 'Maths',
      isTeaching: false,
      location: 'Math Dept Cabin 3',
      status: 'In cabin - available for consultation',
      timetable: {
        'Tue': ['09:00 - Calculus'],
        'Thu': ['11:00 - Linear Algebra'],
      },
    ),
  };
  // -------------------------

  Future<void> _findTeacher() async {
    final teacherName = teacherController.text.trim();
    if (selectedDept == 'Select Department' ||
        selectedBatch == 'Select Batch' ||
        teacherName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select department, batch and enter teacher name')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // simulate network

    final baseKey =
        '${teacherName.toLowerCase()}|${selectedDept.toLowerCase()}|${selectedBatch.toLowerCase()}';
    final fallbackAllBatchKey = '${teacherName.toLowerCase()}|${selectedDept.toLowerCase()}|all';

    TeacherLocationResult? found = _mockDb[baseKey];
    if (found == null) found = _mockDb[fallbackAllBatchKey];

    setState(() {
      _loading = false;
      _result = found;
    });

    if (found == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Not found'),
          content: const Text('Could not find that teacher for the selected department/batch.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  void dispose() {
    teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Teacher (Cabin / Room)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dept + Batch selectors
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedDept,
                      items: departments
                          .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedDept = v ?? 'Select Department'),
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedBatch,
                      items: batches
                          .map((b) => DropdownMenuItem<String>(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedBatch = v ?? 'Select Batch'),
                      decoration: const InputDecoration(labelText: 'Batch'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teacher name
              TextField(
                controller: teacherController,
                decoration: const InputDecoration(
                  labelText: 'Teacher name (e.g., Dr. Smith)',
                  prefixIcon: Icon(Icons.person_search),
                ),
                onSubmitted: (_) => _findTeacher(),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: _loading ? const Text('Searching...') : const Text('Find'),
                      onPressed: _loading ? null : _findTeacher,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_loading) const CircularProgressIndicator(),
              if (!_loading && _result != null) _buildResultCard(_result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(TeacherLocationResult res) {
    final locationLabel = res.isTeaching ? 'Current classroom' : 'Cabin';
    final statusIcon = res.isTeaching ? Icons.class_ : Icons.meeting_room;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(res.teacherName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(statusIcon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('$locationLabel: ${res.location}')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Status: ${res.status}')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_view_week),
              label: const Text('View Timetable'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherTimetablePage(
                      teacherName: res.teacherName,
                      dept: res.dept,
                      timetable: res.timetable,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Navigate'),
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Map navigation not implemented')));
              },
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Simple timetable viewer for teachers (replace with richer UI if desired)
class TeacherTimetablePage extends StatelessWidget {
  final String teacherName;
  final String dept;
  final Map<String, List<String>> timetable;

  const TeacherTimetablePage({
    super.key,
    required this.teacherName,
    required this.dept,
    required this.timetable,
  });

  @override
  Widget build(BuildContext context) {
    final days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Scaffold(
      appBar: AppBar(title: Text('$teacherName — Timetable')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Text('Dept: $dept', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: days.map((d) {
                  final entries = timetable[d] ?? <String>[];
                  return Card(
                    child: ListTile(
                      title: Text(d),
                      subtitle: entries.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entries.map((e) => Text('• $e')).toList(),
                      )
                          : const Text('No classes'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
