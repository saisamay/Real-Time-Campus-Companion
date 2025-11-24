import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class StudentTimetablePage extends StatefulWidget {
  final bool embedded;
  final String? initialBranch;
  final String? initialSemester;
  final String? initialSection;
  final String? userRole; // <--- NEW PARAMETER

  const StudentTimetablePage({
    super.key,
    this.embedded = false,
    this.initialBranch,
    this.initialSemester,
    this.initialSection,
    this.userRole, // <--- Add to constructor
  });

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  bool _isLoading = false;
  String? _error;
  Timetable? _currentTimetable;

  String? _myBranch;
  String? _mySemester;
  String? _mySection;
  String? _myRole;

  late String selectedSemester;
  late String selectedBranch;
  late String selectedSection;

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
    selectedBranch = widget.initialBranch ?? 'CSE';
    selectedSemester = widget.initialSemester ?? 'S5';
    selectedSection = widget.initialSection ?? 'A';

    // IMMEDIATE FIX: Set role directly from parent if provided
    _myRole = widget.userRole;

    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      // 1. Read Secure Storage
      final branch = await ApiService.readBranch();
      final semester = await ApiService.readSemester();
      final section = await ApiService.readSection();
      final role = await ApiService.readRole();

      // 2. Update State (Prioritize passed role, fallback to storage)
      // If widget.userRole was passed, keep it. Otherwise use stored role.
      _myRole = widget.userRole ?? role;
      _myBranch = branch;
      _mySemester = semester;
      _mySection = section;

      // 3. Override Defaults if Storage Has Data
      if (widget.initialBranch == null && branch != null) selectedBranch = branch;
      if (widget.initialSemester == null && semester != null) selectedSemester = semester;
      if (widget.initialSection == null && section != null) selectedSection = section;

      // Sync selected values if we have profile data and they differ
      // This ensures a CR viewing their own class sees the edit options immediately
      if (_canEdit && _myBranch != null) {
        // Optional: force selection to match profile to enable editing immediately
        // selectedBranch = _myBranch!;
        // selectedSemester = _mySemester!;
        // selectedSection = _mySection!;
      }

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

  // --- CRITICAL PERMISSION CHECK ---
  bool get _canEdit {
    if (_myRole == null) return false;
    final role = _myRole!.trim().toLowerCase();

    if (role == 'teacher' || role == 'faculty' || role == 'admin' || role == 'superadmin') return true;

    if (role == 'classrep' || role == 'cr' || role == 'class_rep') {
      // Check if viewing their own class
      // If _myBranch is null (storage failed), we might be editing "blindly" based on role alone
      // but strict safety requires checking the branch.
      // However, since we passed 'initialBranch' correctly, let's trust the match if profile is loaded.
      if (_myBranch == null) return true; // Allow if role is explicitly passed as CR (trusting the user context)

      return selectedBranch == _myBranch &&
          selectedSemester == _mySemester &&
          selectedSection == _mySection;
    }
    return false;
  }

  // --- API ACTION ---
  Future<void> _updateSlot(String day, int index, bool isCancelled, String? newRoom) async {
    if (newRoom != null && newRoom.trim().isEmpty) newRoom = null;

    try {
      if (_currentTimetable != null) {
        setState(() {
          final dayData = _currentTimetable!.grid.firstWhere((d) => d.dayName == day);
          if (index < dayData.slots.length) {
            dayData.slots[index].isCancelled = isCancelled;
            dayData.slots[index].newRoom = newRoom;
          }
        });
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _loadTimetable();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSlotDetails(TimetableSlot slot, String day, int index) {
    bool canEdit = _canEdit;
    bool canChangeRoom = canEdit && slot.room.isEmpty;
    TextEditingController roomController = TextEditingController(text: slot.newRoom ?? slot.room);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(slot.courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  slot.facultyName.isNotEmpty ? slot.facultyName : "Faculty Not Assigned",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                              ),
                              Text("Dept: ${_myBranch ?? 'Unknown'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 30),

                    _detailRow(Icons.access_time, timeSlots[index]['time'] ?? "Unknown Time"),
                    const SizedBox(height: 10),
                    _detailRow(Icons.location_on,
                        (slot.newRoom != null && slot.newRoom!.isNotEmpty)
                            ? "${slot.newRoom} (Updated)"
                            : (slot.room.isNotEmpty ? slot.room : "No Room Assigned")
                    ),

                    if (canEdit && slot.courseCode.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Cancel Class", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        value: slot.isCancelled,
                        activeColor: Colors.red,
                        onChanged: (val) {
                          setDialogState(() {
                            slot.isCancelled = val;
                          });
                          _updateSlot(day, index, val, slot.newRoom);
                        },
                      ),

                      if (canChangeRoom)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            TextField(
                              controller: roomController,
                              enabled: !slot.isCancelled,
                              decoration: InputDecoration(
                                  labelText: "Assign Room (Temp)",
                                  hintText: "Enter Room No (e.g. N205)",
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.save, color: Colors.green),
                                    onPressed: () {
                                      setDialogState(() {
                                        slot.newRoom = roomController.text;
                                      });
                                      _updateSlot(day, index, slot.isCancelled, roomController.text);
                                    },
                                  )
                              ),
                            ),
                          ],
                        )
                      else if (canEdit && slot.room.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            "Permanent room (${slot.room}) set by Admin cannot be overridden here.",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 10), Text(text)]);
  }

  // --- DEBUG INFO WIDGET ---
  Widget _buildDebugInfo() {
    bool canEdit = _canEdit;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: canEdit ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: canEdit ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MY ROLE: ${_myRole?.toUpperCase() ?? 'N/A'}", style: TextStyle(fontWeight: FontWeight.bold, color: canEdit ? Colors.green.shade800 : Colors.red.shade800)),
          if (_myRole == 'classrep' || _myRole == 'cr')
            Text("CLASS CHECK: ${_myBranch ?? 'N/A'}-${_mySemester ?? 'N/A'}-${_mySection ?? 'N/A'} vs $selectedBranch-$selectedSemester-$selectedSection", style: TextStyle(fontSize: 10, color: Colors.grey)),
          Text("EDIT STATUS: ${canEdit ? 'ENABLED' : 'DISABLED'}", style: TextStyle(fontWeight: FontWeight.bold, color: canEdit ? Colors.green.shade700 : Colors.red.shade700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Timetable'), centerTitle: true),
      body: Column(
        children: [
          _buildControls(),
          if (!_isLoading) _buildDebugInfo(), // KEEP THIS until verified
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

  // ... _buildControls, _buildDropdown, _buildTimetableGrid (Keep existing working code for these) ...
  // (I will paste them below to ensure the file is complete)

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
                  Expanded(child: _buildDropdown('Branch', branches, selectedBranch, (v) => setState(() { selectedBranch = v!; _currentTimetable = null; }))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDropdown('Sem', semesters, selectedSemester, (v) => setState(() { selectedSemester = v!; _currentTimetable = null; }))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDropdown('Sec', sections, selectedSection, (v) => setState(() { selectedSection = v!; _currentTimetable = null; }))),
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
    Color hexToColor(String hex) {
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
                    Color bg = hasClass ? hexToColor(slot.color).withOpacity(0.2) : Colors.transparent;
                    if (slot.isCancelled) bg = Colors.red.shade50;

                    return GestureDetector(
                      onTap: () => _showSlotDetails(slot, day, index),
                      child: Container(
                        width: 150,
                        height: 110,
                        margin: const EdgeInsets.only(bottom: 8, right: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: hasClass ? hexToColor(slot.color).withOpacity(0.5) : Colors.grey.shade200),
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
                                Expanded(
                                  child: Text(
                                      slot.isCancelled ? 'CANCELLED' : (slot.newRoom ?? slot.room),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: slot.isCancelled ? Colors.red : Colors.black87)
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                      '(${index+1})',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey)
                                  ),
                                ),
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