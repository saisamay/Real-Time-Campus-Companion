// lib/classrooms_page.dart
import 'package:flutter/material.dart';

class EmptyClassroomsPage extends StatefulWidget {
  const EmptyClassroomsPage({super.key});

  @override
  State<EmptyClassroomsPage> createState() => _ClassroomsPageState();
}

class _ClassroomsPageState extends State<EmptyClassroomsPage> {
  // Simple room occupancy tracking (local to this widget)
  final Map<String, bool?> _roomStatus = {};

  // Filters for this page (local)
  String _filterType = 'Class';
  String _filterFloor = 'Ground';

  int _floorToInt(String floor) {
    switch (floor) {
      case 'Ground':
        return 0;
      case 'First':
        return 1;
      case 'Second':
        return 2;
      case 'Third':
        return 3;
      default:
        return 0;
    }
  }

  List<Map<String, String>> _generateRooms(String type, String floor) {
    final floorNum = _floorToInt(floor);
    final List<Map<String, String>> out = [];
    for (final wing in ['N', 'S']) {
      for (int i = 0; i <= 10; i++) {
        final roomNum = "$floorNum${i.toString().padLeft(2, '0')}";
        final code = '$wing$roomNum${type == "Lab" ? "L" : ""}';
        out.add({'name': code, 'type': type, 'floor': floor, 'wing': wing});
      }
    }
    out.sort((a, b) {
      if (a['wing'] != b['wing']) return a['wing']!.compareTo(b['wing']!);
      final na = int.parse(a['name']!.replaceAll(RegExp(r'[^0-9]'), ''));
      final nb = int.parse(b['name']!.replaceAll(RegExp(r'[^0-9]'), ''));
      return na.compareTo(nb);
    });
    return out;
  }

  void _showOccupancySheet(BuildContext ctx, String roomName) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Theme.of(bCtx).dividerColor, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 16),
            Text(roomName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    setState(() => _roomStatus[roomName] = true);
                    Navigator.pop(bCtx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Marked as Occupied')));
                  },
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Occupied', textAlign: TextAlign.center)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() => _roomStatus[roomName] = false);
                    Navigator.pop(bCtx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Marked as Not occupied')));
                  },
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Not occupied', textAlign: TextAlign.center)),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildStatusPill(BuildContext context, String roomName) {
    final cs = Theme.of(context).colorScheme;
    final status = _roomStatus[roomName];
    String label;
    Color bg;
    Color fg;
    if (status == true) {
      label = 'Occupied';
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    } else if (status == false) {
      label = 'Not occupied';
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    } else {
      label = 'Unknown';
      bg = cs.surfaceVariant;
      fg = cs.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(blurRadius: 8, offset: const Offset(0, 2), color: Colors.black.withOpacity(.15))],
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = const ['Class', 'Lab'];
    final floors = const ['Ground', 'First', 'Second', 'Third'];
    final rooms = _generateRooms(_filterType, _filterFloor);

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _filterType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterFloor,
                  decoration: const InputDecoration(
                    labelText: 'Floor',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: floors.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _filterFloor = v!),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 4 / 3,
            ),
            itemCount: rooms.length,
            itemBuilder: (ctx, i) {
              final r = rooms[i];
              final name = r['name']!;
              return InkWell(
                onTap: () => _showOccupancySheet(context, name),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary, fontSize: 16)),
                          _buildStatusPill(context, name),
                        ]),
                        const Spacer(),
                        Text('${r['type']} • ${r['floor']} Floor • ${r['wing']} Wing', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
