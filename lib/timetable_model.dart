// lib/timetable_model.dart
class Timetable {
  final String id;
  final String semester;
  final String branch;
  final String section;
  final List<Day> grid;

  Timetable({
    required this.id,
    required this.semester,
    required this.branch,
    required this.section,
    required this.grid,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) {
    final gridJson = json['grid'] as List<dynamic>? ?? [];
    final grid = gridJson.map((d) => Day.fromJson(d as Map<String, dynamic>)).toList();
    return Timetable(
      id: json['_id'] ?? '',
      semester: json['semester'] ?? '',
      branch: json['branch'] ?? '',
      section: json['section'] ?? '',
      grid: grid,
    );
  }
}

class Day {
  final String dayName;
  final List<Slot> slots;
  Day({required this.dayName, required this.slots});
  factory Day.fromJson(Map<String, dynamic> json) {
    final list = (json['slots'] as List<dynamic>?) ?? [];
    return Day(dayName: json['dayName'] ?? '', slots: list.map((s) => Slot.fromJson(s as Map<String, dynamic>)).toList());
  }
}

class Slot {
  final String title;
  final String subtitle;
  final String color;
  final String room; // <-- ADDED: Permanent classroom number
  final int? startSlot;
  final int? endSlot;

  Slot({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.room, // <-- ADDED
    this.startSlot,
    this.endSlot
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      color: (json['color'] ?? '#FFFFFFFF').toString(),
      room: (json['room'] ?? '').toString(), // <-- PARSE ROOM
      startSlot: json['startSlot'] != null ? int.tryParse(json['startSlot'].toString()) : null,
      endSlot: json['endSlot'] != null ? int.tryParse(json['endSlot'].toString()) : null,
    );
  }
}
