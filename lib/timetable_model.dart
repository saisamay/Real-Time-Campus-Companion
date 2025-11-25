import 'dart:convert';

// --- SEARCH RESULT MODEL (For Admin Dropdown) ---
class TeacherSearchResult {
  final String id;
  final String name;
  final String dept;
  final String? image;

  TeacherSearchResult({required this.id, required this.name, required this.dept, this.image});

  factory TeacherSearchResult.fromJson(Map<String, dynamic> json) {
    return TeacherSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dept: json['dept'] ?? '',
      image: json['image'],
    );
  }
}

// --- COURSE MODEL ---
class Course {
  final String id;
  final String courseName;
  final String courseCode;
  final String branch;
  final String semester;
  final String section;
  final String facultyName;
  final String facultyImage; // <--- Added
  final String facultyDept;  // <--- Added
  final String color;

  Course({
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.branch,
    required this.semester,
    required this.section,
    required this.facultyName,
    this.facultyImage = '',
    this.facultyDept = '',
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
      facultyImage: json['facultyImage'] ?? '',
      facultyDept: json['facultyDept'] ?? '',
      color: json['color'] ?? '#FFFFFFFF',
    );
  }
}

// --- TIMETABLE SLOT MODEL ---
class TimetableSlot {
  String courseCode;
  String courseName;
  String facultyName;
  String facultyImage;
  String facultyDept;
  String color;
  String type;
  String room;
  bool isCancelled;
  String? newRoom;
  String displayContext;

  // NEW FIELDS
  String startTime;
  String endTime;

  TimetableSlot({
    this.courseCode = '',
    this.courseName = '',
    this.facultyName = '',
    this.facultyImage = '',
    this.facultyDept = '',
    this.color = '#FFFFFFFF',
    this.type = '',
    this.room = '',
    this.isCancelled = false,
    this.newRoom,
    this.displayContext = '',
    this.startTime = '', // Default empty
    this.endTime = '',   // Default empty
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      facultyName: json['facultyName'] ?? '',
      facultyImage: json['facultyImage'] ?? '',
      facultyDept: json['facultyDept'] ?? '',
      color: json['color'] ?? '#FFFFFFFF',
      type: json['type'] ?? '',
      room: json['room'] ?? '',
      isCancelled: json['isCancelled'] ?? false,
      newRoom: json['newRoom'],
      displayContext: json['displayContext'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'facultyName': facultyName,
      'facultyImage': facultyImage,
      'facultyDept': facultyDept,
      'color': color,
      'type': type,
      'room': room,
      'isCancelled': isCancelled,
      'newRoom': newRoom,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

// ... TimetableDay and Timetable classes remain the same ...
// (Just make sure to keep them in the file as they were)
class TimetableDay {
  final String dayName;
  final List<TimetableSlot> slots;
  TimetableDay({required this.dayName, required this.slots});
  factory TimetableDay.fromJson(Map<String, dynamic> json) {
    var list = json['slots'] as List;
    return TimetableDay(dayName: json['dayName'], slots: list.map((i) => TimetableSlot.fromJson(i)).toList());
  }
  Map<String, dynamic> toJson() => {'dayName': dayName, 'slots': slots.map((e) => e.toJson()).toList()};
}

class Timetable {
  final String semester;
  final String branch;
  final String section;
  final List<TimetableDay> grid;
  Timetable({required this.semester, required this.branch, required this.section, required this.grid});
  factory Timetable.fromJson(Map<String, dynamic> json) {
    var list = json['grid'] as List;
    return Timetable(
      semester: json['semester']?.toString() ?? '',
      branch: json['branch'] ?? '',
      section: json['section'] ?? '',
      grid: list.map((i) => TimetableDay.fromJson(i)).toList(),
    );
  }
}