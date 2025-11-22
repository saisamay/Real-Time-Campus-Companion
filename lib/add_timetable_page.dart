import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class AddTimetablePage extends StatefulWidget {
  const AddTimetablePage({super.key});

  @override
  State<AddTimetablePage> createState() => _AddTimetablePageState();
}

class _AddTimetablePageState extends State<AddTimetablePage> {
  bool _isLoading = false;

  // Selection State
  String _branch = 'CSE';
  String _semester = 'S5';
  String _section = 'A';

  // Data
  List<Course> _availableCourses = [];
  List<TimetableDay> _grid = [];

  // Options
  final List<String> _branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'AIE', 'ECE'];
  final List<String> _semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  // CHANGED: Removed 'Sat'
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _initializeEmptyGrid();
    _fetchCourses(); // Initial fetch
  }

  void _initializeEmptyGrid() {
    _grid = _days.map((day) {
      return TimetableDay(
        dayName: day,
        slots: List.generate(9, (_) => TimetableSlot()),
      );
    }).toList();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await ApiService.getCourses(_branch, _semester, _section);
      setState(() => _availableCourses = courses);
    } catch (e) {
      print("Error loading courses: $e");
      setState(() => _availableCourses = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTimetable() async {
    setState(() => _isLoading = true);
    try {
      final gridData = _grid.map((day) => day.toJson()).toList();

      final payload = {
        'semester': _semester,
        'branch': _branch,
        'section': _section,
        'grid': gridData
      };

      await ApiService.addTimetable(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable Created Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editSlot(int dayIndex, int slotIndex) {
    final slot = _grid[dayIndex].slots[slotIndex];

    Course? selectedCourse;
    try {
      selectedCourse = _availableCourses.firstWhere(
            (c) => c.courseCode == slot.courseCode,
      );
    } catch (_) {}

    String type = slot.type.isEmpty ? 'Theory' : slot.type;
    TextEditingController roomCtrl = TextEditingController(text: slot.room);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_days[dayIndex]} - Slot ${slotIndex + 1}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Course>(
                  value: selectedCourse,
                  decoration: const InputDecoration(labelText: 'Select Course'),
                  isExpanded: true,
                  items: _availableCourses.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.courseCode} - ${c.courseName}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Theory', style: TextStyle(fontSize: 12)),
                        value: 'Theory',
                        groupValue: type,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setDialogState(() => type = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Lab', style: TextStyle(fontSize: 12)),
                        value: 'Lab',
                        groupValue: type,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setDialogState(() => type = v!),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Room No (e.g. N305)'),
                ),
                if (selectedCourse != null) ...[
                  const SizedBox(height: 10),
                  Text('Faculty: ${selectedCourse!.facultyName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _grid[dayIndex].slots[slotIndex] = TimetableSlot();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
            FilledButton(
              onPressed: () {
                if (selectedCourse != null) {
                  setState(() {
                    final s = _grid[dayIndex].slots[slotIndex];
                    s.courseCode = selectedCourse!.courseCode;
                    s.courseName = selectedCourse!.courseName;
                    s.facultyName = selectedCourse!.facultyName;

                    // COPY THE NEW FIELDS
                    s.facultyImage = selectedCourse!.facultyImage;
                    s.facultyDept = selectedCourse!.facultyDept;

                    s.color = selectedCourse!.color;
                    s.type = type;
                    s.room = roomCtrl.text;
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Timetable'), centerTitle: true),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Branch', _branches, _branch, (v) => setState(() => _branch = v!))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDropdown('Semester', _semesters, _semester, (v) => setState(() => _semester = v!))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDropdown('Section', _sections, _section, (v) => setState(() => _section = v!))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _fetchCourses,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Load Courses for this Class'),
                    ),
                  ),
                  if (_availableCourses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${_availableCourses.length} courses available', style: const TextStyle(color: Colors.green, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _days.length,
              itemBuilder: (ctx, i) {
                return ExpansionTile(
                  title: Text(_days[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                  initiallyExpanded: true,
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 9,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (ctx, slotIdx) {
                          final slot = _grid[i].slots[slotIdx];
                          final hasData = slot.courseCode.isNotEmpty;

                          return GestureDetector(
                            onTap: () => _editSlot(i, slotIdx),
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: hasData ? _hexToColor(slot.color) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: hasData ? [BoxShadow(color: _hexToColor(slot.color).withOpacity(0.3), blurRadius: 4)] : null,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Slot ${slotIdx + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  if (hasData) ...[
                                    const SizedBox(height: 4),
                                    Text(slot.courseCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                                    Text(slot.type, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                    if (slot.room.isNotEmpty)
                                      Text(slot.room, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ] else
                                    const Icon(Icons.add, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTimetable,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Timetable'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: current,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}