// lib/add_timetable_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddTimetablePage extends StatefulWidget {
  const AddTimetablePage({super.key});

  @override
  State<AddTimetablePage> createState() => _AddTimetablePageState();
}

class _AddTimetablePageState extends State<AddTimetablePage> {
  // configure your backend base URL here
  final String baseUrl = 'http://localhost:4000';
  //final String baseUrl = 'http://10.0.2.2:4000';
  final _formKey = GlobalKey<FormState>();

  // selectors
  String selectedSemester = 'S5';
  String selectedBranch = 'EEE';
  String selectedSection = 'A';

  final List<String> semesters = ['S3', 'S4', 'S5', 'S6'];
  final List<String> branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'Biotech'];
  final List<String> sections = ['A', 'B', 'C', 'N301', 'N302'];

  // days and slots
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final int slotsPerDay = 9;

  // grid: dayName -> list of slot maps {title, subtitle, color}
  late Map<String, List<Map<String, String>>> grid;

  bool _submitting = false;

  // a small palette of colors (hex strings)
  final List<String> palette = [
    '#FFFFFFFF', // white
    '#FFB85C',
    '#9EE6A6',
    '#659CD8',
    '#F4DDB3',
    '#FF5C5C',
    '#8BD9FF',
    '#F7C94E',
    '#FFF799',
    '#6A3F8A',
    '#C75B3A',
    '#2A5DA8',
    '#2CB36A',
    '#FFA4123F' // user's requested color (note: hex should be #FFA4123F or #A4123F — kept for sample)
  ];

  @override
  void initState() {
    super.initState();
    // initialize grid with empty slots
    grid = {
      for (final d in days)
        d: List.generate(
          slotsPerDay,
          (_) => {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'},
        )
    };
  }

  Future<void> _pickColorDialog(String day, int slotIndex) async {
    final cur = grid[day]![slotIndex]['color']!;
    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pick color'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: palette.map((hex) {
                final color = _hexToColor(hex);
                final isSelected = hex.toUpperCase() == cur.toUpperCase();
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(hex),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ],
        );
      },
    );

    if (picked != null) {
      setState(() => grid[day]![slotIndex]['color'] = picked);
    }
  }

  Color _hexToColor(String hex) {
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    return Color(int.parse(cleaned, radix: 16));
  }

  // In both add_timetable_page.dart and edit_timetable_page.dart (MODIFIED)

// ...

  Widget _buildSlotTile(String day, int idx) {
    final slot = grid[day]![idx];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                initialValue: slot['title'],
                decoration: InputDecoration(labelText: 'Slot ${idx + 1} title', isDense: true),
                onChanged: (v) => slot['title'] = v,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _pickColorDialog(day, idx),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _hexToColor(slot['color']!),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: slot['subtitle'],
            decoration: const InputDecoration(labelText: 'Subtitle / Teacher', isDense: true),
            onChanged: (v) => slot['subtitle'] = v,
          ),
          const SizedBox(height: 8), // <-- ADDED SPACER
          TextFormField( // <-- ADDED: ROOM INPUT
            initialValue: slot['room'],
            decoration: const InputDecoration(labelText: 'Permanent Room No.', isDense: true),
            onChanged: (v) => slot['room'] = v,
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      // build grid array as list of day objects
      final List<Map<String, dynamic>> gridArr = days.map((d) {
        final slots = grid[d]!
            .map((s) => {
          'title': s['title'] ?? '',
          'subtitle': s['subtitle'] ?? '',
          'color': s['color'] ?? '#FFFFFFFF',
          'room': s['room'] ?? '', // <-- ADDED
        })
            .toList();
        return {'dayName': d, 'slots': slots};
      }).toList();

// ... rest of the payload and API call

      final payload = {
        'branch': selectedBranch,
        'semester': selectedSemester,
        'section': selectedSection,
        'grid': gridArr,
      };

      final uri = Uri.parse('$baseUrl/api/timetable');
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timetable created successfully')));
        Navigator.of(context).pop(true); // return success
      } else {
        final body = res.body.isNotEmpty ? res.body : 'No response body';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode} — $body')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Timetable'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSemester,
                    decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                    items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedSemester = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBranch,
                    decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder()),
                    items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) => setState(() => selectedBranch = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                    items: sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedSection = v!),
                  ),
                ),
              ]),
            ),

            // Grid editor
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: days.length,
                itemBuilder: (ctx, di) {
                  final d = days[di];
                  return ExpansionTile(
                    initiallyExpanded: di == 0,
                    title: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: List.generate(slotsPerDay, (si) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildSlotTile(d, si),
                    )),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : const Text('Create Timetable'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
