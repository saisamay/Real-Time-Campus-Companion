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
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  // LayerLink for stable dropdown anchoring
  final LayerLink _layerLink = LayerLink();

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
      final courses = await ApiService.getCourses(_branch, _semester, _section);
      setState(() => _availableCourses = courses);

      final timetable = await ApiService.getTimetable(_branch, _semester, _section);
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable Updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${_days[dayIndex]} - Slot ${slotIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Course", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 5),
                DropdownButtonFormField<Course>(
                  value: selectedCourse,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _availableCourses.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.courseCode} - ${c.courseName}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(child: _buildRadioTile('Theory', type, (v) => setDialogState(() => type = v))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildRadioTile('Lab', type, (v) => setDialogState(() => type = v))),
                  ],
                ),
                const SizedBox(height: 15),

                const Text("Search Room", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 5),

                // --- FIXED ROOM SEARCH ---
                RawAutocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                    // Backend now returns max 5 results
                    return await ApiService.searchRoomsWithStatus(
                        textEditingValue.text,
                        _days[dayIndex],
                        slotIndex
                    );
                  },
                  onSelected: (Map<String, dynamic> selection) {
                    if (selection['status'] == 'occupied') {
                      // Warning for Admin
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Room Occupied"),
                          content: Text("Room ${selection['roomNo']} is assigned to ${selection['occupiedBy']}. Proceed?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                            TextButton(
                                onPressed: () {
                                  roomCtrl.text = selection['roomNo'];
                                  Navigator.pop(c);
                                },
                                child: const Text("Use Anyway", style: TextStyle(color: Colors.red))
                            ),
                          ],
                        ),
                      );
                    } else {
                      roomCtrl.text = selection['roomNo'];
                    }
                  },

                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    if (textEditingController.text != roomCtrl.text) {
                      textEditingController.text = roomCtrl.text;
                    }
                    textEditingController.addListener(() {
                      roomCtrl.text = textEditingController.text;
                    });

                    // Using CompositedTransformTarget to anchor the dropdown
                    return CompositedTransformTarget(
                      link: _layerLink,
                      child: TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. N301',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    );
                  },

                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: CompositedTransformFollower(
                        link: _layerLink,
                        showWhenUnlinked: false,
                        targetAnchor: Alignment.bottomLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            // Fixed width prevents layout errors
                            width: 250,
                            // Height limited to ~5 items (60px each)
                            height: 300,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                final isOccupied = option['status'] == 'occupied';
                                return ListTile(
                                  title: Text(option['roomNo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: Container(
                                    width: 12, height: 12,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOccupied ? Colors.red : Colors.green,
                                        boxShadow: [BoxShadow(color: (isOccupied ? Colors.red : Colors.green).withOpacity(0.4), blurRadius: 4)]
                                    ),
                                  ),
                                  subtitle: isOccupied
                                      ? Text("Occupied (${option['occupiedBy']})", style: const TextStyle(fontSize: 10, color: Colors.red))
                                      : const Text("Available", style: TextStyle(fontSize: 10, color: Colors.green)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                if (selectedCourse != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Faculty Assigned:', style: TextStyle(fontSize: 10, color: Colors.blue.shade900)),
                        const SizedBox(height: 4),
                        Text(selectedCourse!.facultyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ]
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

  Widget _buildDropdown(String label, List<String> items, String current, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: current,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRadioTile(String label, String groupValue, ValueChanged<String> onChanged) {
    final isSelected = label == groupValue;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        )),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Timetable'), centerTitle: true),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
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
                                    Text(slot.courseCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(slot.type, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                    if (slot.room.isNotEmpty) Text(slot.room, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ] else const Icon(Icons.edit, size: 16, color: Colors.grey),
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
}