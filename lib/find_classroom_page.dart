import 'package:flutter/material.dart';

class StudentLocationResult {
  final String rollNo;
  final String studentName;
  final String classroom;
  final String status;
  final Map<String, List<String>> timetable;

  StudentLocationResult({
    required this.rollNo,
    required this.studentName,
    required this.classroom,
    required this.status,
    required this.timetable,
  });
}

class FindClassRoomPage extends StatefulWidget {
  const FindClassRoomPage({super.key});

  @override
  State<FindClassRoomPage> createState() => _FindClassRoomPageState();
}

class _FindClassRoomPageState extends State<FindClassRoomPage> {
  final TextEditingController _rollNoController = TextEditingController();

  bool _loading = false;
  StudentLocationResult? _result;

  final Map<String, StudentLocationResult> _mockDatabase = {
    '19BCE1234': StudentLocationResult(
      rollNo: '19BCE1234',
      studentName: 'Alice',
      classroom: 'Room 302, Block B',
      status: 'In lecture: Data Structures',
      timetable: {
        'Monday': ['09:00 AM - DS', '11:00 AM - Algorithms'],
        'Tuesday': ['10:00 AM - AI Lab', '02:00 PM - OS'],
        'Wednesday': ['09:00 AM - DS', '03:00 PM - SE'],
        'Thursday': ['10:00 AM - Free', '02:00 PM - OS Lab'],
        'Friday': ['11:00 AM - Algorithms'],
      },
    ),
    '20BEC5678': StudentLocationResult(
      rollNo: '20BEC5678',
      studentName: 'Bob',
      classroom: 'Electronics Lab 1',
      status: 'Practical session: Circuits',
      timetable: {
        'Monday': ['10:00 AM - Circuits Lab'],
        'Tuesday': ['01:00 PM - Signals'],
        'Wednesday': ['10:00 AM - Free'],
        'Thursday': ['11:00 AM - Microprocessors'],
        'Friday': ['09:00 AM - Signals Lab'],
      },
    ),
    '21BME9101': StudentLocationResult(
      rollNo: '21BME9101',
      studentName: 'Charlie',
      classroom: 'Room 101, Main Building',
      status: 'Free right now',
      timetable: {
        'Monday': ['09:00 AM - Eng Drawing'],
        'Tuesday': ['11:00 AM - Thermodynamics'],
        'Wednesday': ['02:00 PM - Workshop'],
        'Friday': ['09:00 AM - Free'],
      },
    ),
  };

  @override
  void dispose() {
    _rollNoController.dispose();
    super.dispose();
  }

  Future<void> _findStudent() async {
    final rollNo = _rollNoController.text.trim().toUpperCase();
    if (rollNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Roll No.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    final found = _mockDatabase[rollNo];

    setState(() {
      _loading = false;
      _result = found;
    });

    if (found == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Not Found'),
          content: Text('Could not find any student with Roll No: $rollNo.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  void _showTimetable(BuildContext context, StudentLocationResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${result.studentName}'s Timetable"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
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

  Widget _buildInfoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.grey[700]),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
    ],
  );

  Widget _buildResultCard(StudentLocationResult res) {
    return Card(
      margin: const EdgeInsets.only(top: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(res.studentName, style: Theme.of(context).textTheme.headlineSmall),
          Text(res.rollNo, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, 'Current Room: ${res.classroom}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.info_outline, 'Status: ${res.status}'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => _showTimetable(context, res), child: const Text('View Timetable')),
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Classroom by Roll No')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _rollNoController,
              decoration: const InputDecoration(
                labelText: 'Student Roll No. (e.g., 19BCE1234)',
                prefixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _findStudent(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: _loading ? const SizedBox.shrink() : const Icon(Icons.search),
              label: _loading ? const Text('Finding...') : const Text('Find'),
              onPressed: _loading ? null : _findStudent,
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _result != null) _buildResultCard(_result!),
          ]),
        ),
      ),
    );
  }
}
