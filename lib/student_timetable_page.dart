import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class StudentTimetablePage extends StatefulWidget {
  final bool embedded;
  final String? initialBranch;
  final String? initialSemester;
  final String? initialSection;
  final String? userRole;

  const StudentTimetablePage({
    super.key,
    this.embedded = false,
    this.initialBranch,
    this.initialSemester,
    this.initialSection,
    this.userRole,
  });

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  bool _isLoading = false;
  String? _error;
  Timetable? _currentTimetable;

  // Profile Data
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

  final LayerLink _layerLink = LayerLink();
  final TextEditingController _roomSearchController = TextEditingController();

  // Debounce timer to prevent API spam
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    selectedBranch = widget.initialBranch ?? 'CSE';
    selectedSemester = widget.initialSemester ?? 'S5';
    selectedSection = widget.initialSection ?? 'A';
    _myRole = widget.userRole;
    _initialize();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _roomSearchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      final branch = await ApiService.readBranch();
      final semester = await ApiService.readSemester();
      final section = await ApiService.readSection();
      final role = await ApiService.readRole();

      _myRole = widget.userRole ?? role;
      _myBranch = branch;
      _mySemester = semester;
      _mySection = section;

      if (widget.initialBranch == null && branch != null) selectedBranch = branch;
      if (widget.initialSemester == null && semester != null) selectedSemester = semester;
      if (widget.initialSection == null && section != null) selectedSection = section;

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
      final timetable = await ApiService.getTimetable(selectedBranch, selectedSemester, selectedSection);
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

  bool get _canEdit {
    if (_myRole == null) return false;
    final role = _myRole!.trim().toLowerCase();

    if (role == 'teacher' || role == 'faculty' || role == 'admin' || role == 'superadmin') return true;

    if (role == 'classrep' || role == 'cr' || role == 'class_rep') {
      if (widget.initialBranch != null) return true;
      if (_myBranch == null || _mySemester == null || _mySection == null) return true;

      // Strict check: CR can only edit THEIR OWN section
      return selectedBranch == _myBranch &&
          selectedSemester == _mySemester &&
          selectedSection == _mySection;
    }
    return false;
  }

  Future<void> _updateSlot(String day, int index, bool isCancelled, String? newRoom) async {
    if (newRoom != null && newRoom.trim().isEmpty) newRoom = null;

    try {
      // 1. Optimistic Update (Update UI immediately)
      if (_currentTimetable != null) {
        setState(() {
          final dayData = _currentTimetable!.grid.firstWhere((d) => d.dayName == day);
          if (index < dayData.slots.length) {
            dayData.slots[index].isCancelled = isCancelled;
            dayData.slots[index].newRoom = newRoom;
          }
        });
      }

      // 2. Call Backend
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
            const SnackBar(content: Text('Updated Successfully!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      // 3. Revert on Error
      if (mounted) {
        _loadTimetable();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showSlotDetails(TimetableSlot slot, String day, int index) {
    final bool canEdit = _canEdit;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController roomCtrl = TextEditingController(text: slot.newRoom ?? slot.room);
    _roomSearchController.text = roomCtrl.text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              // Ensure bottom padding respects keyboard
                padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue,
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              slot.facultyName.isNotEmpty ? slot.facultyName : "No Faculty",
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            ),
                            if (slot.facultyDept.isNotEmpty)
                              Text("Dept: ${slot.facultyDept}", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                          ]),
                        )
                      ]),
                      const SizedBox(height: 20),
                      _detailRow(Icons.access_time, timeSlots[index]['time'] ?? "-", isDark),
                      const SizedBox(height: 8),
                      _detailRow(
                        Icons.location_on,
                        (slot.newRoom != null && slot.newRoom!.isNotEmpty)
                            ? "${slot.newRoom} (Changed)"
                            : (slot.room.isNotEmpty ? slot.room : "No Room"),
                        isDark,
                      ),

                      if (canEdit && slot.courseCode.isNotEmpty) ...[
                        Divider(height: 30, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        Text("Class Actions", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : Colors.blue)),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Cancel Class", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text("Mark as not occupied", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey)),
                          value: slot.isCancelled,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            setDialogState(() => slot.isCancelled = val);
                            _updateSlot(day, index, val, slot.newRoom);
                          },
                        ),

                        if (!slot.isCancelled) ...[
                          const SizedBox(height: 10),
                          Text("Change Room", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                          const SizedBox(height: 5),

                          // --- NEW: AUTOCOMPLETE WITH CONFLICT DETECTION ---
                          // Using a Map option so we can show status & occupiedBy
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return RawAutocomplete<Map<String, dynamic>>(
                                optionsBuilder: (TextEditingValue textEditingValue) async {
                                  if (textEditingValue.text.isEmpty) return const Iterable.empty();
                                  try {
                                    final List<Map<String, dynamic>> res = await ApiService.searchRoomsWithStatus(
                                      textEditingValue.text,
                                      day,
                                      index,
                                    );
                                    return res;
                                  } catch (e) {
                                    // On error return empty to keep UI stable
                                    return const Iterable.empty();
                                  }
                                },
                                displayStringForOption: (option) => option['roomNo']?.toString() ?? '',
                                onSelected: (Map<String, dynamic> selection) {
                                  final roomNo = selection['roomNo']?.toString() ?? '';
                                  // warn if occupied
                                  if (selection['status'] == 'occupied') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Warning: $roomNo is already assigned to ${selection['occupiedBy'] ?? 'someone'}"),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                  roomCtrl.text = roomNo;
                                  _roomSearchController.text = roomNo;
                                  setDialogState(() => slot.newRoom = roomNo);
                                  // Save immediately
                                  _updateSlot(day, index, slot.isCancelled, roomNo);
                                },

                                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                  // Keep controllers in sync
                                  if (textEditingController.text != roomCtrl.text) {
                                    textEditingController.text = roomCtrl.text;
                                  }
                                  textEditingController.addListener(() {
                                    roomCtrl.text = textEditingController.text;
                                  });

                                  return CompositedTransformTarget(
                                    link: _layerLink,
                                    child: TextFormField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      textCapitalization: TextCapitalization.characters,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                      decoration: InputDecoration(
                                        hintText: "Search Room (e.g. N301)",
                                        prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade400 : Colors.grey),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.save, color: Colors.green),
                                          onPressed: () {
                                            final val = _roomSearchController.text.trim();
                                            setDialogState(() => slot.newRoom = val);
                                            _updateSlot(day, index, slot.isCancelled, val);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                      onChanged: (v) {
                                        // Mirror typed value to internal controller used elsewhere
                                        _roomSearchController.text = v;
                                      },
                                    ),
                                  );
                                },

                                optionsViewBuilder: (context, onSelected, options) {
                                  final opts = options.toList();
                                  // Width: try to use available dialog width, but limit to screen width - side paddings
                                  final overlayWidth = (constraints.maxWidth < 260) ? (MediaQuery.of(context).size.width - 40) : constraints.maxWidth;
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: CompositedTransformFollower(
                                      link: _layerLink,
                                      showWhenUnlinked: false,
                                      targetAnchor: Alignment.bottomLeft,
                                      child: Material(
                                        elevation: 8,
                                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: overlayWidth,
                                          height: 200,
                                          child: ListView.separated(
                                            padding: EdgeInsets.zero,
                                            itemCount: opts.length,
                                            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                            itemBuilder: (context, optIndex) {
                                              final option = opts[optIndex];
                                              final roomNo = option['roomNo']?.toString() ?? '';
                                              final isOccupied = option['status'] == 'occupied';
                                              return ListTile(
                                                title: Text(roomNo, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                                trailing: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isOccupied ? Colors.red : Colors.green,
                                                    boxShadow: [BoxShadow(color: (isOccupied ? Colors.red : Colors.green).withOpacity(0.35), blurRadius: 4)],
                                                  ),
                                                ),
                                                subtitle: isOccupied
                                                    ? Text("Occupied by ${option['occupiedBy'] ?? 'unknown'}", style: const TextStyle(fontSize: 12, color: Colors.red))
                                                    : const Text("Available", style: TextStyle(fontSize: 12, color: Colors.green)),
                                                onTap: () => onSelected(option),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ],

                      // --- CRITICAL UI FIX: EXTRA SCROLL SPACE ---
                      // This invisible box forces the scroll view to have space at the bottom.
                      // When keyboard opens, you can scroll the text field UP,
                      // and the dropdown will have space to render below it.
                      const SizedBox(height: 250),
                    ],
                  ),
                ));
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  Widget _buildDebugInfo() {
    final bool canEdit = _canEdit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: canEdit
            ? (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50)
            : (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Role: ${_myRole ?? 'N/A'} | Edit: ${canEdit ? 'YES' : 'NO'}",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: canEdit
              ? (isDark ? Colors.green.shade300 : Colors.green.shade900)
              : (isDark ? Colors.red.shade300 : Colors.red.shade900),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: widget.embedded
          ? null
          : AppBar(
        title: const Text('Timetable'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : null,
        foregroundColor: isDark ? Colors.white : null,
      ),
      body: Column(
        children: [
          _buildControls(),
          // if (!_isLoading) _buildDebugInfo(), // Debugging role info
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Text(
                _error!,
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey),
              ),
            )
                : _buildTimetableGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 0,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'Branch',
                      branches,
                      selectedBranch,
                          (v) => setState(() { selectedBranch = v!; _currentTimetable = null; }),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      'Sem',
                      semesters,
                      selectedSemester,
                          (v) => setState(() { selectedSemester = v!; _currentTimetable = null; }),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      'Sec',
                      sections,
                      selectedSection,
                          (v) => setState(() { selectedSection = v!; _currentTimetable = null; }),
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loadTimetable,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue.shade700 : const Color(0xFF1E2749),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildDropdown(String label, List<String> items, String current, ValueChanged<String?> onChanged, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.grey.shade400 : Colors.black54),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimetableGrid() {
    if (_currentTimetable == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color hexToColor(String hex) {
      try { return Color(int.parse(hex.replaceAll('#', ''), radix: 16) | 0xFF000000); } catch (_) { return Colors.white; }
    }
    final Map<String, List<TimetableSlot>> gridMap = {};
    for (var d in _currentTimetable!.grid) { gridMap[d.dayName] = d.slots; }

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
                      Text(s['time']!, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey)),
                      Text('(${s['no']})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87)),
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
                    width: 100, height: 110,
                    margin: const EdgeInsets.only(bottom: 8, right: 8),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2A2A) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                    alignment: Alignment.center,
                    child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  ),
                  ...List.generate(9, (index) {
                    final slot = daySlots.length > index ? daySlots[index] : TimetableSlot();
                    final hasClass = slot.courseCode.isNotEmpty;
                    Color bg;
                    if (slot.isCancelled) { bg = isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50; }
                    else if (hasClass) { final base = hexToColor(slot.color); bg = isDark ? base.withOpacity(0.25) : base.withOpacity(0.2); }
                    else { bg = Colors.transparent; }

                    return GestureDetector(
                      onTap: () => _showSlotDetails(slot, day, index),
                      child: Container(
                        width: 150, height: 110,
                        margin: const EdgeInsets.only(bottom: 8, right: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: hasClass ? (isDark ? hexToColor(slot.color).withOpacity(0.6) : hexToColor(slot.color).withOpacity(0.5)) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                        ),
                        child: hasClass ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slot.courseName, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.blueGrey.shade900)),
                            const Spacer(),
                            Text(slot.facultyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(slot.isCancelled ? 'CANCELLED' : (slot.newRoom ?? slot.room), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: slot.isCancelled ? (isDark ? Colors.red.shade300 : Colors.red) : (isDark ? Colors.white : Colors.black87)))),
                                Flexible(child: Text('(${index+1})', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey))),
                              ],
                            )
                          ],
                        ) : Center(child: Text("-", style: TextStyle(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400))),
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
