// lib/find_classroom_page.dart

import 'package:flutter/material.dart';

/// FIND CLASSROOM PAGE
/// Page lets the user select semester & branch, enter friend name,
/// and find the friend's current classroom (uses mock data).
class FindClassRoomPage extends StatefulWidget {
  const FindClassRoomPage({super.key});

  @override
  State<FindClassRoomPage> createState() => _FindClassRoomPageState();
}

class _FindClassRoomPageState extends State<FindClassRoomPage> {
  final List<String> semesters = [
    'Select Semester',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8'
  ];
  final List<String> branches = [
    'Select Branch',
    'CSE',
    'ECE',
    'ME',
    'CE',
    'EE'
  ];

  String selectedSemester = 'Select Semester';
  String selectedBranch = 'Select Branch';
  final TextEditingController friendController = TextEditingController();

  bool _loading = false;
  FriendLocationResult? _result;

  // === Mock database ===
  // Replace with real Firestore/API queries in production.
  final Map<String, FriendLocationResult> _mockDatabase = {
    'alice|5|CSE': FriendLocationResult(
      friendName: 'Alice',
      classroom: 'Room 302, Block B',
      status: 'In lecture: Data Structures',
      timetable: {
        'Mon': ['09:00 AM - DS', '11:00 AM - Algorithms'],
        'Tue': ['10:00 AM - AI Lab', '02:00 PM - OS'],
        'Wed': ['09:00 AM - DS', '03:00 PM - SE'],
      },
    ),
    'bob|3|ECE': FriendLocationResult(
      friendName: 'Bob',
      classroom: 'Electronics Lab 1',
      status: 'Practical session: Circuits',
      timetable: {
        'Mon': ['10:00 AM - Circuits Lab'],
        'Tue': ['01:00 PM - Signals'],
        'Thu': ['11:00 AM - Microprocessors'],
      },
    ),
    'charlie|1|ME': FriendLocationResult(
      friendName: 'Charlie',
      classroom: 'Room 101, Main Building',
      status: 'Free right now',
      timetable: {
        'Mon': ['09:00 AM - Eng Drawing'],
        'Wed': ['02:00 PM - Workshop'],
      },
    ),
  };

  Future<void> _findFriend() async {
    final friendName = friendController.text.trim();
    if (selectedSemester == 'Select Semester' ||
        selectedBranch == 'Select Branch' ||
        friendName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select semester, branch and enter friend name')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final key = '${friendName.toLowerCase()}|${selectedSemester}|${selectedBranch}';
    final found = _mockDatabase[key];

    setState(() {
      _loading = false;
      _result = found;
    });

    if (found == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Not found'),
          content:
          const Text('Could not find that friend with the selected semester & branch.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  void dispose() {
    friendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friend Class Room'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // selectors
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedSemester,
                      items: semesters
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedSemester = v ?? 'Select Semester'),
                      decoration: const InputDecoration(labelText: 'Semester'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedBranch,
                      items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() => selectedBranch = v ?? 'Select Branch'),
                      decoration: const InputDecoration(labelText: 'Branch'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // friend name input
              TextField(
                controller: friendController,
                decoration: const InputDecoration(
                  labelText: 'Friend name (e.g., Alice)',
                  prefixIcon: Icon(Icons.person_search),
                ),
                onSubmitted: (_) => _findFriend(),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: _loading ? const Text('Finding...') : const Text('Find'),
                      onPressed: _loading ? null : _findFriend,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // result area
              if (_loading) const CircularProgressIndicator(),
              if (!_loading && _result != null) _buildResultCard(_result!),
              if (!_loading && _result == null) const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(FriendLocationResult res) {
    return Card(
      margin: const EdgeInsets.only(top: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(res.friendName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.class_, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Current classroom: ${res.classroom}')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('What\'s going on: ${res.status}')),
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
                    builder: (_) => FriendTimetablePage(
                      friendName: res.friendName,
                      semester: selectedSemester,
                      branch: selectedBranch,
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
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Map navigation not implemented')));
              },
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Simple model for mock lookup result
class FriendLocationResult {
  final String friendName;
  final String classroom;
  final String status;
  final Map<String, List<String>> timetable;

  FriendLocationResult({
    required this.friendName,
    required this.classroom,
    required this.status,
    required this.timetable,
  });
}

/// FRIEND TIMETABLE PAGE (kept in same file for convenience)
class FriendTimetablePage extends StatelessWidget {
  final String friendName;
  final String semester;
  final String branch;
  final Map<String, List<String>> timetable;

  const FriendTimetablePage({
    super.key,
    required this.friendName,
    required this.semester,
    required this.branch,
    required this.timetable,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Scaffold(
      appBar: AppBar(title: Text('$friendName\'s Timetable')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Text('Name: $friendName • Sem: $semester • Branch: $branch',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: days.map((d) {
                  final entries = timetable[d] ?? [];
                  return Card(
                    child: ListTile(
                      title: Text(d),
                      subtitle: entries.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entries.map((e) => Text('• $e')).toList(),
                      )
                          : const Text('No classes'),
                      isThreeLine: entries.length > 1,
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
