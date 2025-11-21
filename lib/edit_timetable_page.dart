import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class EditTimetablePage extends StatefulWidget {
  const EditTimetablePage({super.key});

  @override
  State<EditTimetablePage> createState() => _EditTimetablePageState();
}

class _EditTimetablePageState extends State<EditTimetablePage> {
  bool _isLoading = false;
  bool _isGridLoaded = false;

  // Selection State
  String _branch = 'CSE';
  String _semester = 'S5';
  String _section = 'A';

  List<Course> _availableCourses = [];
  List<TimetableDay> _grid = [];

  final List<String> _branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'AIE', 'ECE'];
  final List<String> _semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  // CHANGED: Removed 'Sat'
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _initializeEmptyGrid();
  }

  void _initializeEmptyGrid() {
    _grid = _days.map((day) {
      return TimetableDay(
        dayName: day,
        slots: List.generate(9, (_) => TimetableSlot()),
      );
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isGridLoaded = false;
    });

    try {
      // 1. Fetch Courses
      final courses = await ApiService.getCourses(_branch, _semester, _section);
      setState(() => _availableCourses = courses);

      // 2. Fetch Existing Timetable
      final timetable = await ApiService.getTimetable(_branch, _semester, _section);

      // 3. Merge fetched grid into UI grid
      for (var day in timetable.grid) {
        final uiDayIndex = _grid.indexWhere((d) => d.dayName == day.dayName);
        if (uiDayIndex != -1) {
          for (int i = 0; i < day.slots.length && i < 9; i++) {
            _grid[uiDayIndex].slots[i] = day.slots[i];
          }
        }
      }
      setState(() => _isGridLoaded = true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTimetable() async {
    setState(() => _isLoading = true);
    try {
      final gridData = _grid.map((day) => day.toJson()).toList();
      final payload = {
        'semester': _semester,
        'branch': _branch,
        'section': _section,
        'grid': gridData
      };

      await ApiService.updateTimetable(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable Updated!'), backgroundColor: Colors.green),
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
      selectedCourse = _availableCourses.firstWhere((c) => c.courseCode == slot.courseCode);
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
                    Expanded(child: RadioListTile<String>(title: const Text('Theory', style: TextStyle(fontSize: 12)), value: 'Theory', groupValue: type, contentPadding: EdgeInsets.zero, onChanged: (v) => setDialogState(() => type = v!))),
                    Expanded(child: RadioListTile<String>(title: const Text('Lab', style: TextStyle(fontSize: 12)), value: 'Lab', groupValue: type, contentPadding: EdgeInsets.zero, onChanged: (v) => setDialogState(() => type = v!))),
                  ],
                ),
                TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room No')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _grid[dayIndex].slots[slotIndex] = TimetableSlot());
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
      appBar: AppBar(title: const Text('Edit Timetable'), centerTitle: true),
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
                    child: FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Load Timetable'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_isGridLoaded
                ? const Center(child: Text('Select class and click Load', style: TextStyle(color: Colors.grey)))
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
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Slot ${slotIdx + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  if (hasData) ...[
                                    const SizedBox(height: 4),
                                    Text(slot.courseCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text(slot.type, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                  ] else
                                    const Icon(Icons.edit, size: 16, color: Colors.grey),
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
          if (_isGridLoaded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateTimetable,
                  child: const Text('Update Timetable'),
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