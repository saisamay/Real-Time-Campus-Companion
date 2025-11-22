import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class TeacherTimetablePage extends StatefulWidget {
  const TeacherTimetablePage({super.key});

  @override
  State<TeacherTimetablePage> createState() => _TeacherTimetablePageState();
}

class _TeacherTimetablePageState extends State<TeacherTimetablePage> {
  bool _isLoading = true;
  List<TimetableDay> _grid = [];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final grid = await ApiService.getTeacherTimetable();
      if (mounted) {
        setState(() {
          _grid = grid;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateSlot(String contextStr, String day, int index, bool isCancelled, String? newRoom) async {
    // contextStr is like "CSE S5 A"
    try {
      final parts = contextStr.split(' ');
      if (parts.length < 3) return;

      await ApiService.updateSlot(
        branch: parts[0],
        semester: parts[1],
        section: parts[2],
        dayName: day,
        slotIndex: index,
        isCancelled: isCancelled,
        newRoom: newRoom,
      );

      Navigator.pop(context);
      _loadData(); // Refresh
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!'), backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _showSlotDetails(TimetableSlot slot, String day, int index) {
    final roomCtrl = TextEditingController(text: slot.newRoom ?? slot.room);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class: ${slot.displayContext}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 5),
            Text(slot.courseName, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 15),

            // Teacher Controls
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cancel Class'),
              value: slot.isCancelled,
              activeColor: Colors.red,
              onChanged: (val) => _updateSlot(slot.displayContext, day, index, val, null),
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(labelText: 'Change Room', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => _updateSlot(slot.displayContext, day, index, slot.isCancelled, roomCtrl.text),
                  child: const Text('Update'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Schedule'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _days.length,
        itemBuilder: (ctx, i) {
          final dayName = _days[i];
          // Find data for this day
          final dayData = _grid.firstWhere(
                (d) => d.dayName == dayName,
            orElse: () => TimetableDay(dayName: dayName, slots: List.generate(9, (_) => TimetableSlot())),
          );

          // Check if teacher has ANY class today
          final hasClasses = dayData.slots.any((s) => s.courseCode.isNotEmpty);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: hasClasses ? Colors.white : Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: hasClasses ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: 9,
                    itemBuilder: (ctx, slotIdx) {
                      final slot = dayData.slots.length > slotIdx ? dayData.slots[slotIdx] : TimetableSlot();
                      final hasClass = slot.courseCode.isNotEmpty;

                      if (!hasClass) {
                        // Render Empty Slot
                        return Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text('${slotIdx+1}', style: const TextStyle(color: Colors.grey)),
                        );
                      }

                      // Render Active Class Slot
                      return GestureDetector(
                        onTap: () => _showSlotDetails(slot, dayName, slotIdx),
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: slot.isCancelled ? Colors.red.shade100 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(slot.displayContext, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text(slot.courseCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              if (slot.isCancelled)
                                const Text('CANCELLED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}