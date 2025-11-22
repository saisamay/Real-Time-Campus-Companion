// lib/timetable_model.dart

/// Represents a single slot in the timetable
class TimetableSlot {
  final String courseCode;
  final String courseName;
  final String facultyName;
  final String facultyDept;
  final String facultyImage;
  final String room;
  final String color;
  final bool isCancelled;
  final String? newRoom;

  TimetableSlot({
    this.courseCode = '',
    this.courseName = '',
    this.facultyName = '',
    this.facultyDept = '',
    this.facultyImage = '',
    this.room = '',
    this.color = '#FFFFFF',
    this.isCancelled = false,
    this.newRoom,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      courseCode: json['courseCode']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      facultyName: json['facultyName']?.toString() ?? '',
      facultyDept: json['facultyDept']?.toString() ?? '',
      facultyImage: json['facultyImage']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      color: json['color']?.toString() ?? '#FFFFFF',
      isCancelled: json['isCancelled'] ?? false,
      newRoom: json['newRoom']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'facultyName': facultyName,
      'facultyDept': facultyDept,
      'facultyImage': facultyImage,
      'room': room,
      'color': color,
      'isCancelled': isCancelled,
      'newRoom': newRoom,
    };
  }

  TimetableSlot copyWith({
    String? courseCode,
    String? courseName,
    String? facultyName,
    String? facultyDept,
    String? facultyImage,
    String? room,
    String? color,
    bool? isCancelled,
    String? newRoom,
  }) {
    return TimetableSlot(
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      facultyName: facultyName ?? this.facultyName,
      facultyDept: facultyDept ?? this.facultyDept,
      facultyImage: facultyImage ?? this.facultyImage,
      room: room ?? this.room,
      color: color ?? this.color,
      isCancelled: isCancelled ?? this.isCancelled,
      newRoom: newRoom ?? this.newRoom,
    );
  }
}

/// Represents a day with its slots
class TimetableDay {
  final String dayName;
  final List<TimetableSlot> slots;

  TimetableDay({required this.dayName, required this.slots});

  factory TimetableDay.fromJson(Map<String, dynamic> json) {
    return TimetableDay(
      dayName: json['dayName']?.toString() ?? '',
      slots:
          (json['slots'] as List<dynamic>?)
              ?.map(
                (slot) => TimetableSlot.fromJson(slot as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'slots': slots.map((slot) => slot.toJson()).toList(),
    };
  }
}

/// Represents the complete timetable for a class
class Timetable {
  final String? id;
  final String semester;
  final String branch;
  final String section;
  final List<TimetableDay> grid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Timetable({
    this.id,
    required this.semester,
    required this.branch,
    required this.section,
    required this.grid,
    this.createdAt,
    this.updatedAt,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      semester: json['semester']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      grid:
          (json['grid'] as List<dynamic>?)
              ?.map((day) => TimetableDay.fromJson(day as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'semester': semester,
      'branch': branch,
      'section': section,
      'grid': grid.map((day) => day.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Timetable copyWith({
    String? id,
    String? semester,
    String? branch,
    String? section,
    List<TimetableDay>? grid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Timetable(
      id: id ?? this.id,
      semester: semester ?? this.semester,
      branch: branch ?? this.branch,
      section: section ?? this.section,
      grid: grid ?? this.grid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
