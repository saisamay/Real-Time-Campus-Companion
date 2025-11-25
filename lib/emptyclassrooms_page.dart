import 'package:flutter/material.dart';
import 'api_service.dart';

class EmptyClassroomsPage extends StatefulWidget {
  final String userBranch;
  final String userSection;

  const EmptyClassroomsPage({
    super.key,
    this.userBranch = 'Admin',
    this.userSection = 'Admin',
  });

  @override
  State<EmptyClassroomsPage> createState() => _EmptyClassroomsPageState();
}

class _EmptyClassroomsPageState extends State<EmptyClassroomsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Data State
  List<dynamic> _allClassrooms = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String selectedFloor = 'All Floors';
  String selectedType = 'All';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    _fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Fetch live data (merges DB rooms + Timetable usage)
      final data = await ApiService.getClassroomStatus();
      if (mounted) {
        setState(() {
          _allClassrooms = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  // --- TOGGLE STATUS (Connects to Backend) ---
  void _toggleRoomStatus(String roomName, bool isOccupied) async {
    // 1. Optimistic Update
    final index = _allClassrooms.indexWhere((r) => (r['roomNo'] ?? r['name']) == roomName);
    if (index != -1) {
      setState(() {
        _allClassrooms[index]['isOccupied'] = isOccupied;
        if (isOccupied) {
          _allClassrooms[index]['currentClass'] = {
            'branch': widget.userBranch,
            'section': widget.userSection,
            'subject': 'Manual Booking',
            'teacher': 'Reserved'
          };
        } else {
          _allClassrooms[index]['currentClass'] = null;
        }
      });
    }

    try {
      // 2. Call API
      await ApiService.updateClassroomStatus(
        roomName,
        isOccupied,
        branch: widget.userBranch,
        section: widget.userSection,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOccupied ? 'Room Marked Occupied' : 'Room Marked Available'),
            backgroundColor: isOccupied ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _fetchData(); // Revert on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Filter Logic ---
  List<dynamic> get filteredClassrooms {
    return _allClassrooms.where((room) {
      final name = (room['roomNo'] ?? room['name'] ?? '').toString().toUpperCase();
      final type = (room['type'] ?? 'Class').toString();
      final floor = (room['floor'] ?? '').toString();

      if (searchQuery.isNotEmpty && !name.contains(searchQuery.toUpperCase())) return false;

      if (selectedFloor != 'All Floors') {
        if (floor != selectedFloor && !name.startsWith(selectedFloor[0])) return false;
      }

      if (selectedType != 'All') {
        if (!type.contains(selectedType)) return false;
      }

      return true;
    }).toList();
  }

  int get occupiedCount => _allClassrooms.where((r) => r['isOccupied'] == true).length;
  int get availableCount => _allClassrooms.length - occupiedCount;

  // --- UI COMPONENTS ---

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Filter by Type', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All', Icons.grid_view_rounded),
              const SizedBox(height: 12),
              _buildFilterOption('Class', Icons.class_rounded),
              const SizedBox(height: 12),
              _buildFilterOption('Lab', Icons.science_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String type, IconData icon) {
    final isSelected = selectedType == type;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        setState(() => selectedType = type);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: scheme.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(type, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              actions: [
                // REMOVED REFRESH BUTTON
                // Filter Button - Aligned properly
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _showFilterDialog,
                      tooltip: 'Filter',
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Text(
                  'Classroom Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(blurRadius: 8, color: Colors.black26)]),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                          : [const Color(0xFF00ACC1), const Color(0xFF26C6DA)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(Icons.meeting_room, size: 180, color: Colors.white.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isLoading) const LinearProgressIndicator(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(context, 'Occupied', occupiedCount.toString(), Icons.door_front_door, const Color(0xFFEF4444))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(context, 'Available', availableCount.toString(), Icons.meeting_room_outlined, const Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search classrooms...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Floors', scheme),
                          _buildFilterChip('Ground Floor', scheme),
                          _buildFilterChip('1st Floor', scheme),
                          _buildFilterChip('2nd Floor', scheme),
                          _buildFilterChip('3rd Floor', scheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final room = filteredClassrooms[index];
                  return _buildClassroomCard(context, room);
                }, childCount: filteredClassrooms.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ColorScheme scheme) {
    final isSelected = selectedFloor == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => selectedFloor = label),
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
      ),
    );
  }

  Widget _buildClassroomCard(BuildContext context, Map<String, dynamic> room) {
    final roomName = room['roomNo'] ?? room['name'] ?? 'Unknown';
    final isOccupied = room['isOccupied'] == true;
    final statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final scheme = Theme.of(context).colorScheme;
    final className = room['currentClass'] != null ? room['currentClass']['className'] : null;

    return InkWell(
      onTap: () => _showClassroomDetails(context, room),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [statusColor, statusColor.withOpacity(0.6)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(isOccupied ? Icons.door_front_door : Icons.meeting_room_outlined, color: statusColor, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(isOccupied ? 'BUSY' : 'FREE', style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(roomName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    const SizedBox(height: 4),
                    if (isOccupied && className != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: scheme.errorContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(5)),
                        child: Text(className, style: TextStyle(fontSize: 10, color: scheme.onErrorContainer), maxLines: 1, overflow: TextOverflow.ellipsis),
                      )
                    else
                      Text(room['type'] ?? 'Class', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassroomDetails(BuildContext context, Map<String, dynamic> room) {
    final roomName = room['roomNo'] ?? room['name'];
    final isOccupied = room['isOccupied'] == true;
    final statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final currentClass = room['currentClass'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bCtx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(roomName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(isOccupied ? "OCCUPIED" : "AVAILABLE", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            if (isOccupied && currentClass != null) ...[
              ListTile(leading: const Icon(Icons.book), title: Text("Subject: ${currentClass['subject'] ?? '-'}")),
              ListTile(leading: const Icon(Icons.group), title: Text("Class: ${currentClass['className'] ?? '-'}")),
              ListTile(leading: const Icon(Icons.person), title: Text("Teacher: ${currentClass['teacher'] ?? '-'}")),
            ] else
              const Text("This room is currently free."),
            const SizedBox(height: 20),
            if (!isOccupied)
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () { Navigator.pop(bCtx); _toggleRoomStatus(roomName, true); }, child: const Text("Mark Occupied")))
            else
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { Navigator.pop(bCtx); _toggleRoomStatus(roomName, false); }, child: const Text("Mark Available"))),
          ],
        ),
      ),
    );
  }
}