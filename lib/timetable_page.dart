// lib/timetable_page.dart (RECTIFIED CODE)
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key, required bool embedded});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  // Placeholder for current user role and Timetable ID (will be fetched)
  // !!! IMPORTANT: CHANGE THIS FOR TESTING ROLES: 'student', 'teacher', 'classrep', 'admin'
  String _currentUserRole = 'student';
  String? _currentTimetableId;

  // UI selectors
  String selectedSemester = 'S5';
  String selectedBranch = 'EEE';
  String selectedSection = 'A';

  final List<String> semesters = ['S3', 'S4', 'S5', 'S6'];
  final List<String> branches = ['CSE', 'EEE', 'MECH', 'CIVIL'];
  final List<String> sections = ['A', 'B', 'C', 'D'];

  // Define the time slots (slot number + start-end)
  final List<Map<String, String>> slots = [
    {'no': '1', 'time': '9:00 - 9:50'},
    {'no': '2', 'time': '9:50 - 10:40'},
    {'no': '3', 'time': '10:50 - 11:40'},
    {'no': '4', 'time': '11:40 - 12:30'},
    {'no': '5', 'time': '12:30 - 1:20'},
    {'no': '6', 'time': '1:20 - 2:10'},
    {'no': '7', 'time': '2:10 - 3:00'},
    {'no': '8', 'time': '3:10 - 4:00'},
    {'no': '9', 'time': '4:00 - 4:50'},
  ];

  // REMOVED: fallback sample timetable (timetableData)

  // Live data
  Timetable? _currentTimetable;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyTimetable();
  }

  // Helper to convert color hex string to Color
  Color hexToColor(String hex) {
    String cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    return Color(int.parse(cleaned, radix: 16));
  }

  Future<void> _loadMyTimetable() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getMyTimetable();
      // server may return {timetable: {...}} or timetable directly
      final timJson = (res['timetable'] ?? res) as Map<String, dynamic>;
      final tt = Timetable.fromJson(timJson);
      setState(() {
        _currentTimetable = tt;
        _currentTimetableId = tt.id; // <-- CAPTURE THE ID HERE
        // sync selections with user's section
        if (tt.semester.isNotEmpty) selectedSemester = tt.semester;
        if (tt.branch.isNotEmpty) selectedBranch = tt.branch;
        if (tt.section.isNotEmpty) selectedSection = tt.section;
      });
      // TODO: Phase 2 - After loading timetable, load today's DailyStatus for this ID
    } catch (e) {
      // If loading fails, _currentTimetable remains null, and an error message is shown.
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _onSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.searchTimetable(
        semester: selectedSemester,
        branch: selectedBranch,
        section: selectedSection,
      );
      final timJson = (res['timetable'] ?? res) as Map<String, dynamic>;
      final tt = Timetable.fromJson(timJson);
      setState(() {
        _currentTimetable = tt;
        _currentTimetableId = tt.id;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search error: ${e.toString()}')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // MODIFIED: Implements the role-aware modal for status changes
  void _showCellDetailsFromSlot(String day, int slotIndex, Slot slot) {
    // Placeholder for any existing temporary status loaded from the backend (Phase 2)
    // For now, assume no temporary status, use permanent data.
    final String permanentRoom = slot.room;
    final String currentTitle = slot.title;
    final bool canEdit = ['admin', 'teacher', 'classrep'].contains(_currentUserRole);
    final String timetableId = _currentTimetableId ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Inner state for the temporary changes form
            String? selectedOption; // 'CANCELLED', 'SHIFTED', 'ROOM_CHANGE'
            TextEditingController roomController = TextEditingController(text: permanentRoom);
            TextEditingController shiftController = TextEditingController();

            // Function to handle the API call for setting status
            Future<void> _applyStatusChange() async {
              if (selectedOption == null || timetableId.isEmpty) return;

              Map<String, dynamic> details = {};
              if (selectedOption == 'ROOM_CHANGE') {
                details['newRoom'] = roomController.text;
              } else if (selectedOption == 'SHIFTED') {
                details['newTime'] = shiftController.text;
              }

              // NOTE: This will be implemented in Phase 2 using ApiService
              // try {
              //   await ApiService.setDailyStatus(
              //     timetableId: timetableId,
              //     dayName: day,
              //     slotIndex: slotIndex,
              //     status: selectedOption!,
              //     details: details
              //   );
              //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully!')));
              // } catch (e) {
              //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
              // }

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status set: $selectedOption. API call pending.')));
              Navigator.pop(context);
            }

            List<Widget> _buildEditOptions() {
              if (!canEdit) return [];

              return [
                const Divider(),
                Text('⚠️ Temporary Class Status Update (Resets 6:00 PM)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                // Option 1: Class Cancelled
                RadioListTile<String>(
                  title: const Text('Class Cancelled'),
                  value: 'CANCELLED',
                  groupValue: selectedOption,
                  onChanged: (val) => setState(() => selectedOption = val),
                ),

                // Option 2: Class Timing Shift
                RadioListTile<String>(
                  title: const Text('Class Timing Shift'),
                  value: 'SHIFTED',
                  groupValue: selectedOption,
                  onChanged: (val) => setState(() => selectedOption = val),
                ),
                if (selectedOption == 'SHIFTED')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: shiftController,
                      decoration: const InputDecoration(
                        labelText: 'New Timing Details (e.g., 10:00 - 10:50)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),

                // Option 3: Room No Change
                RadioListTile<String>(
                  title: const Text('Room No Change'),
                  value: 'ROOM_CHANGE',
                  groupValue: selectedOption,
                  onChanged: (val) => setState(() => selectedOption = val),
                ),
                if (selectedOption == 'ROOM_CHANGE')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'New Temporary Room No.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: Phase 2 - Call API to CLEAR temporary status
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status Cleared. API call pending.')));
                        Navigator.pop(context);
                      },
                      child: const Text('Clear Status'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: selectedOption != null ? _applyStatusChange : null,
                      child: const Text('Apply Temporary Change'),
                    ),
                  ],
                ),
              ];
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(slot.subtitle),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Day: $day'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text('Slot: ${slots[slotIndex]['no']}  •  ${slots[slotIndex]['time']}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      // Displaying Permanent Room
                      title: Text('Permanent Room: ${permanentRoom.isNotEmpty ? permanentRoom : 'N/A'}'),
                      // TODO: Phase 2 - Add subtitle here to show current temporary room/status if DailyStatus exists
                    ),

                    ..._buildEditOptions(),

                    if (!canEdit)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Note: This is the standard schedule. Status updates (cancellations/shifts) will appear here if changed by faculty.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // DELETED: _showCellDetails function is removed.

  // Attractive controls card
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: [
              // Semester
              SizedBox(
                width: 150,
                child: InputDecorator(
                  decoration: InputDecoration(
                    label: const Text('Semester'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSemester,
                      items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() {
                        if (v != null) selectedSemester = v;
                      }),
                    ),
                  ),
                ),
              ),

              // Branch
              SizedBox(
                width: 150,
                child: InputDecorator(
                  decoration: InputDecoration(
                    label: const Text('Branch'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedBranch,
                      items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() {
                        if (v != null) selectedBranch = v;
                      }),
                    ),
                  ),
                ),
              ),

              // Section
              SizedBox(
                width: 150,
                child: InputDecorator(
                  decoration: InputDecoration(
                    label: const Text('Section'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSection,
                      items: sections.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() {
                        if (v != null) selectedSection = v;
                      }),
                    ),
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _onSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the whole timetable as a scrollable table-like widget
  Widget _buildTimetable() {
    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('Error: $_error')),
      );
    }

    // if we have server timetable, use it. If not, treat it as empty.
    final hasServer = _currentTimetable != null && _currentTimetable!.grid.isNotEmpty;
    // Base days structure (Mon-Fri) always needed for UI structure
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    // create mapping dayName -> List<Slot> (if server present)
    final Map<String, List<Slot>> gridMap = {};
    if (hasServer) {
      for (final d in _currentTimetable!.grid) {
        gridMap[d.dayName] = d.slots;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // header row for slot times and numbers (compact)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120), // empty cell for top-left
              ...slots.map((s) => Container(
                width: 160,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
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

          // rows for each day
          ...days.map((day) {
            // Get slots, providing empty slots if the timetable or day is missing
            final List<Slot> cells = gridMap[day] ?? List.generate(9, (_) => Slot(title: '', subtitle: '', color: '#FFFFFFFF', room: ''));

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // day label
                Container(
                  width: 120,
                  height: 100,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.black12)),
                  child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                // cells
                ...List.generate(9, (index) {
                  final Slot slot = cells[index]; // Always guaranteed to be a Slot object
                  final bg = hexToColor(slot.color);
                  return GestureDetector(
                    onTap: () => _showCellDetailsFromSlot(day, index, slot),
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
                          // title (bigger, fits ~10 big chars)
                          Text(
                            slot.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // ADDED: Display the permanent room number
                          Text(
                            slot.room.isNotEmpty ? 'Room: ${slot.room}' : 'No Room',
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey[700], fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // subtitle (20-30 chars, allow up to 2 lines)
                          Expanded(
                            child: Text(
                              slot.subtitle,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text('(${slots[index]['no']})', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          )
                        ],
                      ),
                    ),
                  );
                })
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Table'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildControls(),
          const SizedBox(height: 6),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Text('Error: $_error')))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTimetable(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}