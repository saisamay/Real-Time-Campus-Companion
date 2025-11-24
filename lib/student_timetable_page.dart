import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Uppercase Input
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

  // Logged-in User's Profile
  String? _myBranch;
  String? _mySemester;
  String? _mySection;
  String? _myRole;

  // UI Selectors
  String selectedSemester = 'S5';
  String selectedBranch = 'CSE';
  String selectedSection = 'A';

  final List<String> semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  final List<String> branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'AIE', 'ECE'];
  final List<String> sections = ['A', 'B', 'C', 'D', 'E'];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

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
      final branch = await ApiService.readBranch();
      final semester = await ApiService.readSemester();
      final section = await ApiService.readSection();
      final role = await ApiService.readRole();

      // --- DEBUG PRINT: CHECK CONSOLE TO SEE YOUR ROLE ---
      print("--- DEBUG INFO ---");
      print("Role: '$role'");
      print("My Branch: $branch | Selected: $selectedBranch");
      print("------------------");

      _myBranch = branch;
      _mySemester = semester;
      _mySection = section;
      _myRole = role;

      if (branch != null) selectedBranch = branch;
      if (semester != null) selectedSemester = semester;
      if (section != null) selectedSection = section;

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

  // --- STRICT PERMISSION CHECK ---
  // --- STRICT PERMISSION CHECK ---
  bool get _canEdit {
    if (_myRole == null) return false;
    final role = _myRole!.trim().toLowerCase();

    // 1. Teacher/Faculty: Can edit EVERYTHING.
    if (role == 'teacher' || role == 'faculty') return true;

    // 2. Class Rep: Can edit ONLY their own class.
    if (role == 'classrep' || role == 'cr') {
      // Check if viewing their own timetable
      return selectedBranch == _myBranch &&
          selectedSemester == _mySemester &&
          selectedSection == _mySection;
    }

    // 3. Student: Cannot edit anything
    return false;
  }

  // Check if user is a student (read-only mode)
  bool get _isStudent {
    if (_myRole == null) return true; // Default to student if no role
    final role = _myRole!.trim().toLowerCase();
    return role == 'student' || role == 'std';
  }

  // --- API ACTION ---
  Future<void> _updateSlot(String day, int index, bool isCancelled, String? newRoom) async {
    if (newRoom != null && newRoom.trim().isEmpty) newRoom = null;

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
      if (mounted) {
        Navigator.pop(context); // Close Popup
        _loadTimetable();       // Refresh Data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- THE POPUP UI ---
  void _showSlotDetails(TimetableSlot slot, String day, int index) {
    // Controller for the room text field
    final roomCtrl = TextEditingController(text: slot.newRoom ?? slot.room);
    bool isCancelledState = slot.isCancelled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Needed to move up with keyboard
      backgroundColor: Colors.transparent, // For rounded corners
      builder: (ctx) {
        // StatefulBuilder allows us to toggle switches inside the sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Calculate padding to avoid keyboard covering content
            final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
              child: SingleChildScrollView( // <--- FIXES THE RENDER OVERFLOW ERROR
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. HEADER (Image + Name) ---
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: (slot.facultyImage.isNotEmpty)
                              ? NetworkImage(slot.facultyImage)
                              : null,
                          child: (slot.facultyImage.isEmpty)
                              ? Text(
                            slot.facultyName.isNotEmpty ? slot.facultyName[0].toUpperCase() : "?",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.facultyName.isNotEmpty ? slot.facultyName : "Free Slot",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              if (slot.facultyDept.isNotEmpty)
                                Text("Dept: ${slot.facultyDept}", style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    // --- 2. DETAILS ---
                    _detailRow(Icons.calendar_today, 'Day', day),
                    _detailRow(Icons.access_time, 'Time', timeSlots[index]['time']!),
                    if(slot.courseCode.isNotEmpty) ...[
                      _detailRow(Icons.book, 'Subject', slot.courseName),
                      _detailRow(Icons.room, 'Room', slot.room.isEmpty ? "N/A" : slot.room),
                    ],

                    // --- 3. EDIT CONTROLS (Only if Teacher or CR) ---
                    if (_canEdit && slot.courseCode.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Manage Class", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                            const SizedBox(height: 10),

                            // Cancel Toggle
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Cancel Class", style: TextStyle(fontWeight: FontWeight.w600)),
                              value: isCancelledState,
                              activeColor: Colors.red,
                              onChanged: (val) {
                                setModalState(() => isCancelledState = val);
                              },
                            ),

                            const SizedBox(height: 8),

                            // Room Input (Disabled if cancelled)
                            TextField(
                              controller: roomCtrl,
                              enabled: !isCancelledState,
                              textCapitalization: TextCapitalization.characters, // Forces Caps on Keyboard
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp("[A-Z0-9-]")), // Forces Caps in Logic
                              ],
                              decoration: InputDecoration(
                                labelText: "Change Room (Temp)",
                                hintText: "e.g. AB-101",
                                prefixIcon: const Icon(Icons.meeting_room),
                                filled: true,
                                fillColor: isCancelledState ? Colors.grey.shade200 : Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _updateSlot(day, index, isCancelledState, roomCtrl.text),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E2749),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Update Slot", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (slot.courseCode.isNotEmpty && _myRole == 'classrep') ...[
                      // Message for CRs looking at WRONG section
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.lock, size: 20, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(child: Text("You can only edit your own section.", style: TextStyle(color: Colors.orange, fontSize: 12))),
                            ],
                          ),
                        ),
                      )
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Timetable'), centerTitle: true),
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
                : _buildTimetableGrid(),
          ),
        ],
      ),
    );
  }

  // --- CONTROLS & GRID (Same as before) ---
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2749),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                  ),
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
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimetableGrid() {
    if (_currentTimetable == null) return const SizedBox.shrink();
    Color _hexToColor(String hex) {
      try { return Color(int.parse(hex.replaceAll('#', ''), radix: 16) | 0xFF000000); } catch (_) { return Colors.white; }
    }

    final Map<String, List<TimetableSlot>> gridMap = {};
    for (var d in _currentTimetable!.grid) {
      gridMap[d.dayName] = d.slots;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 100),
                ...timeSlots.map((s) => Container(
                  width: 150,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Text(s['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('(${s['no']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
              ],
            ),
            ..._days.map((day) {
              final List<TimetableSlot> daySlots = gridMap[day] ?? List.generate(9, (_) => TimetableSlot());
              return Row(
                children: [
                  Container(
                    width: 100,
                    height: 110,
                    margin: const EdgeInsets.only(bottom: 8, right: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    alignment: Alignment.center,
                    child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...List.generate(9, (index) {
                    final slot = daySlots.length > index ? daySlots[index] : TimetableSlot();
                    final hasClass = slot.courseCode.isNotEmpty;
                    Color bg = hasClass ? _hexToColor(slot.color).withOpacity(0.2) : Colors.transparent;
                    if (slot.isCancelled) bg = Colors.red.shade50;

                    return GestureDetector(
                      onTap: () => _showSlotDetails(slot, day, index),
                      child: Container(
                        width: 150,
                        height: 110,
                        margin: const EdgeInsets.only(bottom: 8, right: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: hasClass ? _hexToColor(slot.color).withOpacity(0.5) : Colors.grey.shade200),
                        ),
                        child: hasClass ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slot.courseName, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey.shade900)),
                            const Spacer(),
                            Text(slot.facultyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(slot.isCancelled ? 'CANCELLED' : (slot.newRoom ?? slot.room), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: slot.isCancelled ? Colors.red : Colors.black87)),
                                Text('(${index+1})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            )
                          ],
                        ) : const Center(child: Text("-", style: TextStyle(color: Colors.grey))),
                      ),
                    );
                  })
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}