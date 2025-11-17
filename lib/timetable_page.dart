// lib/timetable_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key, required bool embedded});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
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

  // fallback sample timetable (used if backend returns nothing)
  Map<String, List<Map<String, String>>> timetableData = {
    'Mon': [
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE303', 'subtitle': '', 'color': '#FFB85C'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': '23EEE301', 'subtitle': '', 'color': '#659CD8'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE301', 'subtitle': '', 'color': '#659CD8'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
    'Tue': [
      {'title': 'CIR-23LSE301', 'subtitle': 'Verbal Skills / Aptitude', 'color': '#F4DDB3'},
      {'title': 'CIR-23LSE301', 'subtitle': 'Aptitude Skills', 'color': '#F4DDB3'},
      {'title': 'Counselling', 'subtitle': 'Counselling Hour', 'color': '#FF5C5C'},
      {'title': '23EEE351', 'subtitle': '23EEE369 / 23ELC366', 'color': '#8BD9FF'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE367', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE381', 'subtitle': '23EEE382', 'color': '#FFF799'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
    'Wed': [
      {'title': '23EEE302', 'subtitle': '', 'color': '#6A3F8A'},
      {'title': '23EEE303', 'subtitle': '', 'color': '#C75B3A'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE367', 'subtitle': '', 'color': '#F7C94E'},
      {'title': '23EEE302', 'subtitle': '', 'color': '#6A3F8A'},
      {'title': '23EEE304', 'subtitle': '', 'color': '#9EE6A6'},
      {'title': 'Tutorial 1', 'subtitle': '', 'color': '#2CB36A'},
      {'title': 'Tutorial 2', 'subtitle': '', 'color': '#2CB36A'},
    ],
    'Thu': [
      {'title': '23EEE367', 'subtitle': '23EEE335 (Common Elective)', 'color': '#F7C94E'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE381', 'subtitle': '23EEE382', 'color': '#FFF799'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '', 'subtitle': '-', 'color': '#FFFFFFFF'},
      {'title': '23EEE351', 'subtitle': '23EEE369', 'color': '#8BD9FF'},
      {'title': 'CIR-23LSE301', 'subtitle': 'Soft Skills', 'color': '#F4DDB3'},
      {'title': 'CIR-23LSE301', 'subtitle': 'Code HR', 'color': '#F4DDB3'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
    'Fri': [
      {'title': '23EEE301', 'subtitle': '', 'color': '#2A5DA8'},
      {'title': '23EEE303', 'subtitle': '', 'color': '#C75B3A'},
      {'title': '23EEE302', 'subtitle': '', 'color': '#6A3F8A'},
      {'title': '23EEE301', 'subtitle': '', 'color': '#2A5DA8'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE335', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
      {'title': '23EEE351', 'subtitle': '23EEE369 / 23ELC366', 'color': '#8BD9FF'},
      {'title': 'Tutorial 3', 'subtitle': '', 'color': '#2CB36A'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
  };

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
        // sync selections with user's section
        if (tt.semester.isNotEmpty) selectedSemester = tt.semester;
        if (tt.branch.isNotEmpty) selectedBranch = tt.branch;
        if (tt.section.isNotEmpty) selectedSection = tt.section;
      });
    } catch (e) {
      // keep fallback data but show error
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

  void _showCellDetailsFromSlot(String day, int slotIndex, Slot slot) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: [
                ListTile(
                  title: Text(slot.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(slot.subtitle),
                ),
                const Divider(),
                ListTile(title: Text('Day: $day')),
                ListTile(title: Text('Slot: ${slots[slotIndex]['no']}  •  ${slots[slotIndex]['time']}')),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCellDetails(String day, int slotIndex, Map<String, String> cell) {
    // backward-compat fallback (uses sample data structure)
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: [
                ListTile(
                  title: Text(cell['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(cell['subtitle'] ?? ''),
                ),
                const Divider(),
                ListTile(title: Text('Day: $day')),
                ListTile(title: Text('Slot: ${slots[slotIndex]['no']}  •  ${slots[slotIndex]['time']}')),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

    // if we have server timetable, use it; else fallback to local sample
    final hasServer = _currentTimetable != null && _currentTimetable!.grid.isNotEmpty;
    final days = hasServer
        ? _currentTimetable!.grid.map((d) => d.dayName).toList()
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

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
            // get cells either from server Slot objects or fallback sample map
            final List<dynamic> cellsDynamic = hasServer
                ? (gridMap[day] ?? List.generate(9, (_) => Slot(title: '', subtitle: '', color: '#FFFFFFFF')))
                : (timetableData[day] ?? List.generate(9, (_) => {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'}));

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
                  if (hasServer) {
                    final Slot slot = cellsDynamic[index] as Slot;
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
                            const SizedBox(height: 6),
                            // subtitle (20-30 chars, allow up to 3 lines)
                            Expanded(
                              child: Text(
                                slot.subtitle,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 3,
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
                  } else {
                    final cell = cellsDynamic[index] as Map<String, String>;
                    final bg = hexToColor(cell['color'] ?? '#FFFFFFFF');
                    final title = cell['title'] ?? '';
                    final subtitle = cell['subtitle'] ?? '';
                    return GestureDetector(
                      onTap: () => _showCellDetails(day, index, cell),
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
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // subtitle (20-30 chars, allow up to 3 lines)
                            Expanded(
                              child: Text(
                                subtitle,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 3,
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
                  }
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
