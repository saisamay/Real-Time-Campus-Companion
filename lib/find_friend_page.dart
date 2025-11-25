import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class FindFriendPage extends StatefulWidget {
  const FindFriendPage({super.key});

  @override
  State<FindFriendPage> createState() => _FindFriendPageState();
}

class _FindFriendPageState extends State<FindFriendPage> {
  // Selected User Data
  Map<String, dynamic>? _selectedUser;
  Timetable? _friendTimetable;
  bool _isLoadingSchedule = false;

  // Live Status
  String _currentRoom = "Search to see";
  String _nextClassLocation = "-";
  String _currentStatus = "";

  // Dropdown Anchor (Critical for layout stability)
  final LayerLink _layerLink = LayerLink();

  // Time Slots definition
  final List<Map<String, String>> _timeSlots = [
    {'start': '09:00', 'end': '09:50'},
    {'start': '09:50', 'end': '10:40'},
    {'start': '10:50', 'end': '11:40'},
    {'start': '11:40', 'end': '12:30'},
    {'start': '12:30', 'end': '13:20'},
    {'start': '13:20', 'end': '14:10'},
    {'start': '14:10', 'end': '15:10'},
    {'start': '15:10', 'end': '16:00'},
    {'start': '16:00', 'end': '16:50'},
  ];

  // --- FETCH SCHEDULE & CALCULATE LOCATION ---
  Future<void> _fetchFriendSchedule(Map<String, dynamic> user) async {
    setState(() {
      _selectedUser = user;
      _isLoadingSchedule = true;
    });

    try {
      final branch = user['branch'];
      final semester = user['semester']?.toString();
      final section = user['section'];

      if (branch == null || semester == null || section == null) {
        setState(() {
          _currentRoom = "N/A";
          _nextClassLocation = "N/A";
          _currentStatus = "Class details not found";
          _isLoadingSchedule = false;
        });
        return;
      }

      // 1. Get Timetable
      final timetable = await ApiService.getTimetable(branch, semester, section);
      _friendTimetable = timetable;

      // 2. Calculate Status
      _calculateLiveStatus();

    } catch (e) {
      setState(() {
        _currentRoom = "Unknown";
        _nextClassLocation = "-";
        _currentStatus = "Could not fetch schedule";
      });
    } finally {
      if (mounted) setState(() => _isLoadingSchedule = false);
    }
  }

  void _calculateLiveStatus() {
    if (_friendTimetable == null) return;

    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    // Check weekend
    if (now.weekday > 5) {
      setState(() {
        _currentRoom = "Home / Hostel";
        _currentStatus = "Weekend - No Classes";
        _nextClassLocation = "See you Monday!";
      });
      return;
    }

    final dayName = days[now.weekday - 1];
    final todayGrid = _friendTimetable!.grid.firstWhere(
          (d) => d.dayName == dayName,
      orElse: () => TimetableDay(dayName: dayName, slots: []),
    );

    int currentMinutes = now.hour * 60 + now.minute;

    TimetableSlot? currentSlot;
    TimetableSlot? nextSlot;

    // Find Current & Next
    for (int i = 0; i < _timeSlots.length; i++) {
      final startStr = _timeSlots[i]['start']!;
      final endStr = _timeSlots[i]['end']!;

      final startMin = _toMinutes(startStr);
      final endMin = _toMinutes(endStr);

      if (i < todayGrid.slots.length) {
        final slot = todayGrid.slots[i];
        // A slot is valid if it has a course and isn't cancelled
        final hasClass = slot.courseCode.isNotEmpty && !slot.isCancelled;

        // Check if NOW is in this slot
        if (currentMinutes >= startMin && currentMinutes < endMin) {
          currentSlot = slot;
        }

        // Check for FIRST upcoming slot
        if (currentMinutes < startMin && nextSlot == null && hasClass) {
          nextSlot = slot;
        }
      }
    }

    // Update UI Variables
    setState(() {
      // 1. Current Status
      if (currentSlot != null && currentSlot.courseCode.isNotEmpty && !currentSlot.isCancelled) {
        final room = currentSlot.newRoom ?? currentSlot.room;
        _currentRoom = room.isNotEmpty ? room : "Room Not Assigned";
        _currentStatus = "In Class: ${currentSlot.courseName}";
      } else {
        _currentRoom = "Free / Campus";
        _currentStatus = "Currently Free";
      }

      // 2. Next Class
      if (nextSlot != null) {
        final nextRoom = nextSlot.newRoom ?? nextSlot.room;
        _nextClassLocation = nextRoom.isNotEmpty ? nextRoom : "TBA";
      } else {
        _nextClassLocation = "No more classes today";
      }
    });
  }

  int _toMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Find Friend'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      // SingleChildScrollView prevents render overflow when keyboard opens
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- SEARCH BAR ---
            _buildSearchBar(isDark, cardColor),

            const SizedBox(height: 30),

            // --- RESULT CARD OR EMPTY STATE ---
            if (_selectedUser != null)
              _buildFriendCard(isDark, cardColor)
            else
              Container(
                height: 300,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text("Enter Roll No to find your friend", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

            if (_isLoadingSchedule)
              const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator())
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color cardColor) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return RawAutocomplete<Map<String, dynamic>>(
            // 1. CALLING SPECIFIC FRIEND API (ROLL NO ONLY)
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
              return await ApiService.searchFriends(textEditingValue.text);
            },
            displayStringForOption: (option) => option['rollNo'] ?? '',
            onSelected: (Map<String, dynamic> selection) {
              FocusScope.of(context).unfocus(); // Hide keyboard
              _fetchFriendSchedule(selection);
            },

            // 2. INPUT FIELD (Anchor Target)
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return CompositedTransformTarget(
                link: _layerLink,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Search Roll No (e.g. AM.SC...)",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                ),
              );
            },

            // 3. DROPDOWN LIST (Anchor Follower)
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.bottomLeft,
                  child: Material(
                    elevation: 8,
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      // Ensure width matches the text field
                      width: constraints.maxWidth,
                      constraints: const BoxConstraints(maxHeight: 250),
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        separatorBuilder: (_,__) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (option['profileImage'] != null && option['profileImage'].isNotEmpty)
                                  ? NetworkImage(option['profileImage'])
                                  : null,
                              child: (option['profileImage'] == null || option['profileImage'].isEmpty)
                                  ? Text(option['name'][0]) : null,
                            ),
                            title: Text(option['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            subtitle: Text(option['rollNo'] ?? 'No Roll No', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
    );
  }

  Widget _buildFriendCard(bool isDark, Color cardColor) {
    final user = _selectedUser!;
    final imageUrl = user['profileImage'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),

          // 1. Profile Image (Large)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade100, width: 4),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
              backgroundColor: Colors.blue.shade50,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.blue)
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // 2. Name & Roll No
          Text(
            user['name'] ?? "Unknown",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user['rollNo'] ?? "NO ROLL NO",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // 3. Class Details
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem("Semester", user['semester']?.toString() ?? "-", isDark),
                _buildVerticalDivider(),
                _buildInfoItem("Branch", user['branch'] ?? "-", isDark),
                _buildVerticalDivider(),
                _buildInfoItem("Section", user['section'] ?? "-", isDark),
              ],
            ),
          ),

          // 4. Live Location Box
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? [Colors.blue.shade900, Colors.blue.shade800] : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Left Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on, color: isDark ? Colors.white : Colors.blue.shade800, size: 28),
                ),
                const SizedBox(width: 16),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CURRENT LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey)),
                      const SizedBox(height: 2),
                      Text(
                          _currentRoom,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentStatus,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Next Class Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                  ),
                  child: Column(
                    children: [
                      const Text("NEXT", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(_nextClassLocation, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }
}