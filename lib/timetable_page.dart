import 'package:flutter/material.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  // UI selectors
  String selectedSemester = 'S5';
  String selectedBranch = 'EEE';
  String selectedSection = 'N302';

  final List<String> semesters = ['S3', 'S4', 'S5', 'S6'];
  final List<String> branches = ['CSE', 'EEE', 'MECH', 'CIVIL'];
  final List<String> sections = ['N301', 'N302', 'N303', 'N304'];

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

  // Example timetable data: Map<day, List<cell>>
  // Each cell: {title, subtitle (optional), color}
  // For real app, fetch from backend depending on semester/branch/section
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
      {'title': 'CIR-23LSE301\nVerbal Skills', 'subtitle': '', 'color': '#F4DDB3'},
      {'title': 'CIR-23LSE301\nAptitude Skills', 'subtitle': '', 'color': '#F4DDB3'},
      {'title': 'Counselling Hour', 'subtitle': '', 'color': '#FF5C5C'},
      {'title': '23EEE351\n23EEE369', 'subtitle': '23ELC366', 'color': '#8BD9FF'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE367\n23EEE335', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
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
      {'title': '23EEE367\n23EEE335', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE381\n23EEE382', 'subtitle': '', 'color': '#FFF799'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE351', 'subtitle': '23EEE369', 'color': '#8BD9FF'},
      {'title': 'CIR-23LSE301\nSoft Skills', 'subtitle': 'N112C', 'color': '#F4DDB3'},
      {'title': 'CIR-23LSE301\nCode HR', 'subtitle': 'A202', 'color': '#F4DDB3'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
    'Fri': [
      {'title': '23EEE301', 'subtitle': '', 'color': '#2A5DA8'},
      {'title': '23EEE303', 'subtitle': '', 'color': '#C75B3A'},
      {'title': '23EEE302', 'subtitle': '', 'color': '#6A3F8A'},
      {'title': '23EEE301', 'subtitle': '', 'color': '#2A5DA8'},
      {'title': 'Lunch Break', 'subtitle': '', 'color': '#FFFFFFFF'},
      {'title': '23EEE335', 'subtitle': 'Common Elective', 'color': '#F7C94E'},
      {'title': '23EEE351', 'subtitle': '23EEE369\n23ELC366', 'color': '#8BD9FF'},
      {'title': 'Tutorial 3', 'subtitle': '', 'color': '#2CB36A'},
      {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
    ],
  };

  // Helper to convert color hex string to Color
  Color hexToColor(String hex) {
    String cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    return Color(int.parse(cleaned, radix: 16));
  }

  // When you change selectors, you may fetch fresh data from backend
  void _onSearch() {
    // For this sample, we don't fetch from backend.
    // Replace this method to call your API using selectedSemester/Branch/Section.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching: $selectedSemester / $selectedBranch / $selectedSection')),
    );
    setState(() {
      // In a real app you would update timetableData from API response here.
    });
  }

  // Show bottom sheet with details of the cell
  void _showCellDetails(String day, int slotIndex, Map<String, String> cell) {
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
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build table header for slots
  Widget _buildSlotHeader() {
    return Row(
      children: [
        const SizedBox(width: 120), // day label placeholder
        // scrollable slot headers
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: slots.map((s) {
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                  child: Column(
                    children: [
                      Text(s['time']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('(${s['no']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Build the whole timetable as a scrollable table-like widget
  Widget _buildTimetable() {
    // Days order
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // header row for slot times and numbers
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 120), // empty cell for top-left
              ...slots.map((s) => Container(
                    width: 160,
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                    child: Column(
                      children: [
                        Text(s['time']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        Text('(${s['no']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
            ],
          ),
          // rows for each day
          ...days.map((day) {
            final cells = timetableData[day]!;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // day label
                Container(
                  width: 120,
                  height: 90,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.black12)),
                  child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                // cells
                ...List.generate(cells.length, (index) {
                  final cell = cells[index];
                  final bg = hexToColor(cell['color'] ?? '#FFFFFFFF');
                  final title = cell['title'] ?? '';
                  final subtitle = cell['subtitle'] ?? '';
                  return GestureDetector(
                    onTap: () => _showCellDetails(day, index, cell),
                    child: Container(
                      width: 160,
                      height: 90,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 11)),
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

  // Build the control row (semester/branch/section + search)
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Semester
          SizedBox(
            width: 140,
            child: InputDecorator(
              decoration: const InputDecoration(label: Text('Semester'), border: OutlineInputBorder()),
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
            width: 140,
            child: InputDecorator(
              decoration: const InputDecoration(label: Text('Branch'), border: OutlineInputBorder()),
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
            width: 140,
            child: InputDecorator(
              decoration: const InputDecoration(label: Text('Section'), border: OutlineInputBorder()),
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
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
          ),
        ],
      ),
    );
  }

  // Build the legend/modal that shows slot numbers and times
  Widget _buildSlotLegend() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: slots.map((s) {
            return Container(
              width: 160,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text('Slot ${s['no']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(s['time']!, textAlign: TextAlign.center),
                ],
              ),
            );
          }).toList(),
        ),
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTimetable(),
                  _buildSlotLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

