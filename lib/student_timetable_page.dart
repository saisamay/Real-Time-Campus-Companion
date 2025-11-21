import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class StudentTimetablePage extends StatefulWidget {
  final bool embedded;
  const StudentTimetablePage({super.key, this.embedded = false});

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  bool _isLoading = false;
  String? _error;

  // Currently Loaded Timetable
  Timetable? _currentTimetable;

  // Logged-in User's Profile (For Permission Checks)
  String? _myBranch;
  String? _mySemester;
  String? _mySection;
  String? _myRole;

  // UI Selectors (What we are viewing currently)
  String selectedSemester = 'S5';
  String selectedBranch = 'CSE';
  String selectedSection = 'A';

  // Dropdown Options
  final List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  final List<String> branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'AIE', 'ECE'];
  final List<String> sections = ['A', 'B', 'C', 'D', 'E'];

  // Days to display
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  // Time Slot Definitions (Matches your reference UI)
  final List<Map<String, String>> timeSlots = [
    {'no': '1', 'time': '09:00 - 09:50'},
    {'no': '2', 'time': '09:50 - 10:40'},
    {'no': '3', 'time': '10:50 - 11:40'},
    {'no': '4', 'time': '11:40 - 12:30'},
    {'no': '5', 'time': '12:30 - 01:20'},
    {'no': '6', 'time': '01:20 - 02:10'},
    {'no': '7', 'time': '02:10 - 03:00'},
    {'no': '8', 'time': '03:10 - 04:00'},
    {'no': '9', 'time': '04:00 - 04:50'},
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      // 1. Read User Profile & Role from Storage
      final branch = await ApiService.readBranch();
      final semester = await ApiService.readSemester();
      final section = await ApiService.readSection();
      final role = await ApiService.readRole();

      _myBranch = branch;
      _mySemester = semester;
      _mySection = section;
      _myRole = role;

      // 2. Default the selectors to the user's own class
      if (branch != null) selectedBranch = branch;
      if (semester != null) selectedSemester = semester;
      if (section != null) selectedSection = section;

      // 3. Load that timetable initially
      await _loadTimetable();

    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimetable() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Fetch specific timetable based on dropdowns
      final timetable = await ApiService.getTimetable(
          selectedBranch,
          selectedSemester,
          selectedSection
      );
      setState(() => _currentTimetable = timetable);
    } catch (e) {
      setState(() {
        _currentTimetable = null;
        _error = "No timetable found for $selectedBranch $selectedSemester $selectedSection";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PERMISSION CHECK ---
  bool get _canEdit {
    // 1. Must be Class Rep
    if (_myRole != 'classrep') return false;

    // 2. Must be viewing THEIR OWN section
    // We compare strictly to avoid CRs editing other classes
    return selectedBranch == _myBranch &&
        selectedSemester == _mySemester &&
        selectedSection == _mySection;
  }

  // --- ACTIONS ---
  Future<void> _updateSlot(String day, int index, bool isCancelled, String? newRoom) async {
    try {
      await ApiService.updateSlot(
        semester: selectedSemester,
        branch: selectedBranch,
        section: selectedSection,
        dayName: day,
        slotIndex: index,
        isCancelled: isCancelled,
        newRoom: newRoom,
      );
      Navigator.pop(context); // Close bottom sheet
      _loadTimetable(); // Refresh grid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated Successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI HELPERS ---
  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  // --- POPUP DETAILS ---
  void _showSlotDetails(TimetableSlot slot, String day, int index) {
    // For the room change text field
    final roomCtrl = TextEditingController(text: slot.newRoom ?? slot.room);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              slot.courseName.isEmpty ? 'Free Slot' : slot.courseName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (slot.courseCode.isNotEmpty)
              Text(slot.courseCode, style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const Divider(),

            // Info Rows
            _detailRow(Icons.calendar_today, 'Day', day),
            _detailRow(Icons.access_time, 'Time', timeSlots.length > index ? timeSlots[index]['time']! : 'Slot ${index+1}'),
            if (slot.courseCode.isNotEmpty) ...[
              _detailRow(Icons.person, 'Faculty', slot.facultyName),
              _detailRow(Icons.room, 'Room', slot.newRoom != null
                  ? '${slot.newRoom} (Changed)'
                  : slot.room.isEmpty ? 'N/A' : slot.room),
            ],

            if (slot.isCancelled)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Chip(label: Text('Class Cancelled'), backgroundColor: Colors.red, labelStyle: TextStyle(color: Colors.white)),
              ),

            // --- EDIT CONTROLS (Only if _canEdit is true) ---
            if (_canEdit && slot.courseCode.isNotEmpty) ...[
              const Divider(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Class Rep Controls', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),

                    // Toggle Cancel
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cancel Class'),
                      value: slot.isCancelled,
                      activeColor: Colors.red,
                      onChanged: (val) => _updateSlot(day, index, val, null),
                    ),

                    // Change Room
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: roomCtrl,
                            decoration: const InputDecoration(
                              labelText: 'New Room',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _updateSlot(day, index, slot.isCancelled, roomCtrl.text),
                          child: const Text('Update'),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (slot.courseCode.isNotEmpty && _myRole == 'classrep') ...[
              // CR viewing someone else's timetable
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Note: You can only edit the timetable for your own section.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only show AppBar if not embedded in another page
      appBar: widget.embedded ? null : AppBar(title: const Text('Timetable'), centerTitle: true),
      body: Column(
        children: [
          // 1. Search Controls
          _buildControls(),

          // 2. Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
                : _buildTimetableGrid(), // The scrollable table
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildDropdown('Branch', branches, selectedBranch, (v) => setState(() => selectedBranch = v!))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDropdown('Sem', semesters, selectedSemester, (v) => setState(() => selectedSemester = v!))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDropdown('Sec', sections, selectedSection, (v) => setState(() => selectedSection = v!))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loadTimetable,
                  icon: const Icon(Icons.search),
                  label: const Text('View Timetable'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current, ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- THE GRID UI (Matches your reference code) ---
  Widget _buildTimetableGrid() {
    if (_currentTimetable == null) return const SizedBox.shrink();

    // Map DayName -> List of Slots for easy lookup
    final Map<String, List<TimetableSlot>> gridMap = {};
    for (var d in _currentTimetable!.grid) {
      gridMap[d.dayName] = d.slots;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Row (Time Slots)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120), // Empty corner for "Days" column
                ...timeSlots.map((s) => Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black12), color: Colors.white),
                  child: Column(
                    children: [
                      Text(s['time']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('(${s['no']})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
              ],
            ),

            // 2. Rows for Each Day
            ..._days.map((day) {
              // Get slots or empty list
              final List<TimetableSlot> daySlots = gridMap[day] ?? List.generate(9, (_) => TimetableSlot());

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Label Column
                  Container(
                    width: 120,
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  // Slot Cells
                  ...List.generate(9, (index) {
                    final slot = daySlots.length > index ? daySlots[index] : TimetableSlot();
                    final hasClass = slot.courseCode.isNotEmpty;

                    // Color Logic
                    Color bg = hasClass ? _hexToColor(slot.color).withOpacity(0.3) : Colors.white;
                    if (slot.isCancelled) bg = Colors.red.shade100;

                    return GestureDetector(
                      onTap: () => _showSlotDetails(slot, day, index),
                      child: Container(
                        width: 160,
                        height: 100,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasClass) ...[
                              // Title
                              Text(
                                slot.courseName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Subtitle (Faculty)
                              Expanded(
                                child: Text(
                                  slot.facultyName,
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Bottom: Room & Slot No
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (slot.isCancelled)
                                    const Text('CANCELLED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                                  else if (slot.newRoom != null)
                                    Text(slot.newRoom!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11))
                                  else
                                    Text(slot.room, style: TextStyle(fontSize: 11, color: Colors.blueGrey[700], fontWeight: FontWeight.bold)),

                                  Text('(${index+1})', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                                ],
                              ),
                            ] else
                              const Center(child: Text('-', style: TextStyle(color: Colors.grey))),
                          ],
                        ),
                      ),
                    );
                  })
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}