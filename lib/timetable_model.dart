import 'dart:convert';

// --- COURSE MODEL (For Admin Selection) ---
class Course {
  final String id;
  final String courseName;
  final String courseCode;
  final String branch;
  final String semester; // "S5"
  final String section;
  final String facultyName;
  final String color;

  Course({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.branch,
    required this.semester,
    required this.section,
    required this.facultyName,
    required this.color,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      branch: json['branch'] ?? '',
      semester: json['semester'] ?? '',
      section: json['section'] ?? '',
      facultyName: json['facultyName'] ?? '',
      color: json['color'] ?? '#FFFFFFFF',
    );
  }
}

// --- TIMETABLE SLOT MODEL ---
class TimetableSlot {
  String courseCode;
  String courseName;
  String facultyName;
  String color;
  String type; // "Theory", "Lab", or ""
  String room;
  bool isCancelled;
  String? newRoom; // Nullable
  String displayContext; // For teachers (e.g. "CSE S5 A")

  TimetableSlot({
    this.courseCode = '',
    this.courseName = '',
    this.facultyName = '',
    this.color = '#FFFFFFFF',
    this.type = '',
    this.room = '',
    this.isCancelled = false,
    this.newRoom,
    this.displayContext = '',
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      facultyName: json['facultyName'] ?? '',
      color: json['color'] ?? '#FFFFFFFF',
      type: json['type'] ?? '',
      room: json['room'] ?? '',
      isCancelled: json['isCancelled'] ?? false,
      newRoom: json['newRoom'],
      displayContext: json['displayContext'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'facultyName': facultyName,
      'color': color,
      'type': type,
      'room': room,
      'isCancelled': isCancelled,
      'newRoom': newRoom,
    };
  }
}

// --- TIMETABLE DAY MODEL ---
class TimetableDay {
  final String dayName;
  final List<TimetableSlot> slots;

  TimetableDay({required this.dayName, required this.slots});

  factory TimetableDay.fromJson(Map<String, dynamic> json) {
    var list = json['slots'] as List;
    List<TimetableSlot> slotsList = list.map((i) => TimetableSlot.fromJson(i)).toList();
    return TimetableDay(dayName: json['dayName'], slots: slotsList);
  }

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'slots': slots.map((e) => e.toJson()).toList(),
    };
  }
}

// --- MAIN TIMETABLE MODEL ---
class Timetable {
  final String semester;
  final String branch;
  final String section;
  final List<TimetableDay> grid;

  Timetable({
    required this.semester,
    required this.branch,
    required this.section,
    required this.grid,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) {
    var list = json['grid'] as List;
    List<TimetableDay> gridList = list.map((i) => TimetableDay.fromJson(i)).toList();
    return Timetable(
      semester: json['semester']?.toString() ?? '',
      branch: json['branch'] ?? '',
      section: json['section'] ?? '',
      grid: gridList,
    );
  }
}