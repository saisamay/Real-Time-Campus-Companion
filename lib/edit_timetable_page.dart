// lib/edit_timetable_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditTimetablePage extends StatefulWidget {
  const EditTimetablePage({super.key});

  @override
  State<EditTimetablePage> createState() => _EditTimetablePageState();
}

class _EditTimetablePageState extends State<EditTimetablePage> {
  final String baseUrl = 'http://10.0.2.2:4000';

  final _formKey = GlobalKey<FormState>();

  String selectedSemester = 'S5';
  String selectedBranch = 'EEE';
  String selectedSection = 'A';

  final List<String> semesters = ['S3', 'S4', 'S5', 'S6'];
  final List<String> branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'Biotech'];
  final List<String> sections = ['A', 'B', 'C', 'N301', 'N302'];

  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final int slotsPerDay = 9;

  late Map<String, List<Map<String, String>>> grid;
  bool _loading = false;
  bool _saving = false;
  String? _timetableId;

  final List<String> palette = [
    '#FFFFFFFF', '#FFB85C', '#9EE6A6', '#659CD8', '#F4DDB3', '#FF5C5C', '#8BD9FF', '#F7C94E', '#FFF799', '#6A3F8A', '#C75B3A', '#2A5DA8', '#2CB36A', '#FFA4123F'
  ];

  @override
  void initState() {
    super.initState();
    grid = {
      for (final d in days)
        d: List.generate(slotsPerDay, (_) => {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'})
    };
  }

  Color _hexToColor(String hex) {
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    return Color(int.parse(cleaned, radix: 16));
  }

  Future<void> _fetchTimetable() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$baseUrl/api/timetable')
          .replace(queryParameters: {'semester': selectedSemester, 'branch': selectedBranch, 'section': selectedSection});
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // body might be { success: true, timetable: {...} } or timetable directly
        final timetable = body is Map && body['timetable'] != null ? body['timetable'] : body;
        if (timetable == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timetable not found')));
        } else {
          _timetableId = timetable['_id'] ?? timetable['id'] ?? null;
          final List<dynamic> gridArr = timetable['grid'] ?? [];
          for (final dayObj in gridArr) {
            final dayName = dayObj['dayName'];
            final slots = (dayObj['slots'] as List<dynamic>);
            grid[dayName] = List.generate(slotsPerDay, (i) {
              if (i < slots.length) {
                final s = slots[i] as Map<String, dynamic>;
                return {
                  'title': s['title']?.toString() ?? '',
                  'subtitle': s['subtitle']?.toString() ?? '',
                  'color': s['color']?.toString() ?? '#FFFFFFFF'
                };
              } else {
                return {'title': '', 'subtitle': '', 'color': '#FFFFFFFF'};
              }
            });
          }
          setState(() {});
        }
      } else if (res.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timetable not found (404)')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
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
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel'))],
        );
      },
    );

    if (picked != null) {
      setState(() => grid[day]![slotIndex]['color'] = picked);
    }
  }

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
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: _hexToColor(slot['color']!), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12))),
            ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: slot['subtitle'],
            decoration: const InputDecoration(labelText: 'Subtitle / room / teacher', isDense: true),
            onChanged: (v) => slot['subtitle'] = v,
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final gridArr = days.map((d) {
        final slots = grid[d]!.map((s) => {'title': s['title'], 'subtitle': s['subtitle'], 'color': s['color']}).toList();
        return {'dayName': d, 'slots': slots};
      }).toList();

      final payload = {'branch': selectedBranch, 'semester': selectedSemester, 'section': selectedSection, 'grid': gridArr};

      if (_timetableId != null) {
        final uri = Uri.parse('$baseUrl/api/timetable/$_timetableId');
        final res = await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timetable updated')));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: ${res.statusCode}')));
        }
      } else {
        // Fallback: try POST to create if no id (makes endpoint flexible)
        final uri = Uri.parse('$baseUrl/api/timetable');
        final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
        if (res.statusCode == 200 || res.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timetable created')));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Timetable'),
        centerTitle: true,
      ),
      body: SafeArea(
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(children: [
              FilledButton.icon(
                onPressed: _loading ? null : _fetchTimetable,
                icon: const Icon(Icons.download),
                label: _loading ? const Text('Loading...') : const Text('Load'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: _saving ? const Text('Saving...') : const Text('Save'),
                ),
              ),
            ]),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: days.length,
              itemBuilder: (ctx, di) {
                final d = days[di];
                return ExpansionTile(
                  initiallyExpanded: di == 0,
                  title: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: List.generate(slotsPerDay, (si) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: _buildSlotTile(d, si))),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
