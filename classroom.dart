import 'package:flutter/material.dart';

class ClassroomsPage extends StatefulWidget {
  const ClassroomsPage({super.key});

  @override
  State<ClassroomsPage> createState() => _ClassroomsPageState();
}

class _ClassroomsPageState extends State<ClassroomsPage> {
  // Occupancy + type state
  final Map<String, bool?> _roomStatus = {};           // key = visible name (e.g., N001 or N001L)
  final Map<String, String> _roomTypeOverride = {};    // key = base (e.g., N001) -> 'Class' | 'Lab'

  String _filterType = 'Class';
  String _filterFloor = 'Ground';
  String _filterOccupancy = 'All'; // All / Occupied / Not occupied

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Build + filter
    var rooms = _generateRoomsExclusive(_filterType, _filterFloor);
    rooms = rooms.where((r) {
      final status = _roomStatus[r['name']!];
      if (_filterOccupancy == 'All') return true;
      if (_filterOccupancy == 'Occupied') return status == true;
      if (_filterOccupancy == 'Not occupied') return status == false;
      return true;
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 10),

        // Responsive filter bar (prevents overflow)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _ResponsiveFilters(
            type: _filterType,
            floor: _filterFloor,
            occ: _filterOccupancy,
            onType: (v) => setState(() => _filterType = v),
            onFloor: (v) => setState(() => _filterFloor = v),
            onOcc: (v) => setState(() => _filterOccupancy = v),
          ),
        ),

        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 4 / 3),
            itemCount: rooms.length,
            itemBuilder: (ctx, i) {
              final r = rooms[i];
              final name = r['name']!;
              final type = r['type']!;
              final floor = r['floor']!;
              final wing = r['wing']!;
              return InkWell(
                onTap: () => _showOccupancySheet(context, name, r['base']!, type),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary, fontSize: 16)),
                            _buildStatusPill(context, name),
                          ],
                        ),
                        const Spacer(),
                        Text('$type • $floor Floor • $wing Wing',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
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

  // ---------- data & logic ----------
  int _floorToInt(String floor) {
    switch (floor) {
      case 'Ground': return 0;
      case 'First':  return 1;
      case 'Second': return 2;
      case 'Third':  return 3;
      default:       return 0;
    }
  }

  String _defaultTypeForBase(String base) {
    final digits = RegExp(r'\d+').firstMatch(base)?.group(0) ?? '0';
    final last = int.parse(digits[digits.length - 1]);
    return (last == 0 || last == 5) ? 'Lab' : 'Class';
    // Change rule if required (or use a provided list) and rebuild.
  }

  List<Map<String, String>> _generateRoomsExclusive(String filterType, String floor) {
    final floorNum = _floorToInt(floor);
    final List<Map<String, String>> out = [];

    for (final wing in ['N', 'S']) {
      for (int i = 0; i <= 10; i++) {
        final roomNum = "$floorNum${i.toString().padLeft(2, '0')}";
        final base = '$wing$roomNum'; // e.g., N001
        final assigned = _roomTypeOverride[base] ?? _defaultTypeForBase(base);

        if (assigned == filterType) {
          final visibleName = assigned == 'Lab' ? '${base}L' : base;

          out.add({
            'name': visibleName,
            'base': base,
            'type': assigned,
            'floor': floor,
            'wing': wing,
          });
        }
      }
    }

    out.sort((a, b) {
      if (a['wing'] != b['wing']) return a['wing']!.compareTo(b['wing']!);
      final na = int.parse(a['base']!.replaceAll(RegExp(r'[^0-9]'), ''));
      final nb = int.parse(b['base']!.replaceAll(RegExp(r'[^0-9]'), ''));
      return na.compareTo(nb);
    });
    return out;
  }

  // ---------- UI helpers ----------
  void _showOccupancySheet(BuildContext ctx, String roomName, String base, String currentType) {
    final assigned = _roomTypeOverride[base];
    final effectiveType = assigned ?? currentType;

    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(bCtx).dividerColor, borderRadius: BorderRadius.circular(999))),
            ]),
            const SizedBox(height: 16),
            Text(roomName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Base: $base • Type: $effectiveType', textAlign: TextAlign.center),
            const SizedBox(height: 16),

            Row(
              children: [
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
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() { _roomTypeOverride[base] = 'Class'; });
                      Navigator.pop(bCtx);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$base set as Class')));
                    },
                    child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Set as Class')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() { _roomTypeOverride[base] = 'Lab'; });
                      Navigator.pop(bCtx);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$base set as Lab')));
                    },
                    child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Set as Lab')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, String roomName) {
    final cs = Theme.of(context).colorScheme;
    final status = _roomStatus[roomName];
    String label; Color bg; Color fg;

    if (status == true) { label = 'Occupied'; bg = cs.errorContainer; fg = cs.onErrorContainer; }
    else if (status == false) { label = 'Not occupied'; bg = cs.primaryContainer; fg = cs.onPrimaryContainer; }
    else { label = 'Unknown'; bg = cs.surfaceVariant; fg = cs.onSurfaceVariant; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(blurRadius: 8, offset: const Offset(0, 2), color: Colors.black.withOpacity(.15))]),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// -------- Responsive Filters (Type / Floor / Occupancy) --------
class _ResponsiveFilters extends StatelessWidget {
  final String type, floor, occ;
  final ValueChanged<String> onType, onFloor, onOcc;

  const _ResponsiveFilters({
    super.key,
    required this.type,
    required this.floor,
    required this.occ,
    required this.onType,
    required this.onFloor,
    required this.onOcc,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        final cols = w >= 900 ? 3 : (w >= 600 ? 2 : 1);
        final spacing = 12.0;
        final itemW = (w - (spacing * (cols - 1))) / cols;

        Widget box(Widget child) => SizedBox(width: itemW, child: child);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            box(
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'Type', border: OutlineInputBorder(),
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const ['Class', 'Lab'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => onType(v!),
              ),
            ),
            box(
              DropdownButtonFormField<String>(
                value: floor,
                decoration: const InputDecoration(
                  labelText: 'Floor', border: OutlineInputBorder(),
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const ['Ground', 'First', 'Second', 'Third']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => onFloor(v!),
              ),
            ),
            box(
              DropdownButtonFormField<String>(
                value: occ,
                decoration: const InputDecoration(
                  labelText: 'Filter', border: OutlineInputBorder(),
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const ['All', 'Occupied', 'Not occupied']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => onOcc(v!),
              ),
            ),
          ],
        );
      },
    );
  }
}

//use it in main

//// import 'classrooms_page.dart';
// // ...
// const ClassroomsPage(),