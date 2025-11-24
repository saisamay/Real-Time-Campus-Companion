import 'package:flutter/material.dart';
import 'api_service.dart';

class EmptyClassroomsPage extends StatefulWidget {
  const EmptyClassroomsPage({super.key});

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

  // Filter State
  String selectedFloor = 'All Floors';
  String selectedType = 'All'; // 'Class' or 'Lab'
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
      // Fetch live data calculated from Timetable + Classroom DB
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

  // --- Logic to Filter the List ---
  List<dynamic> get filteredClassrooms {
    return _allClassrooms.where((room) {
      final name = (room['name'] ?? '').toString().toUpperCase();
      final type = (room['type'] ?? 'Class').toString();
      final floor = (room['floor'] ?? '').toString();

      // 1. Search
      if (searchQuery.isNotEmpty && !name.contains(searchQuery.toUpperCase())) {
        return false;
      }

      // 2. Floor Filter
      if (selectedFloor != 'All Floors') {
        // If your DB stores "1st Floor", match it.
        // If it stores just "1", you might need to adjust this check.
        if (floor != selectedFloor && !name.startsWith(selectedFloor[0])) {
          // Fallback: check if room name starts with floor number (e.g. "101" starts with "1")
          return false;
        }
      }

      // 3. Type Filter
      if (selectedType != 'All') {
        // Simple normalization to match "Class" vs "Classroom"
        if (!type.contains(selectedType)) return false;
      }

      return true;
    }).toList();
  }

  int get occupiedCount => _allClassrooms.where((r) => r['isOccupied'] == true).length;
  int get availableCount => _allClassrooms.length - occupiedCount;

  // --- UI BUILDER METHODS ---

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Filter by Type', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
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
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? scheme.primary : scheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 12),
            Text(
              type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? scheme.primary : scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: scheme.primary, size: 24),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            actions: [
              // Refresh Button
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchData),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.white),
                        if (selectedType != 'All')
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter',
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Classroom Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                ),
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
                      right: -50, top: -50,
                      child: Icon(Icons.meeting_room, size: 180, color: Colors.white.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- STATS & SEARCH ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isLoading) const LinearProgressIndicator(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(context, 'Occupied', occupiedCount.toString(), Icons.door_front_door, const Color(0xFFEF4444), isDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(context, 'Available', availableCount.toString(), Icons.meeting_room_outlined, const Color(0xFF10B981), isDark),
                      ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Floors', scheme),
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

          // --- CLASSROOM GRID ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: _isLoading
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : _error != null
                ? SliverToBoxAdapter(child: Center(child: Text("Error loading data: $_error")))
                : filteredClassrooms.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: Text("No Classrooms Found")))
                : SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final room = filteredClassrooms[index];
                return _buildClassroomCard(context, room, isDark);
              }, childCount: filteredClassrooms.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ],
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
        labelStyle: TextStyle(
          color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildClassroomCard(BuildContext context, Map<String, dynamic> room, bool isDark) {
    // Data Extraction
    final roomName = room['name'] ?? 'Unknown';
    final isOccupied = room['isOccupied'] == true;
    final isLab = (room['type'] ?? '').toString().contains('Lab');
    final capacity = room['capacity'] ?? 0;
    final floor = room['floor'] ?? 'Unknown';

    // Details if occupied
    final currentClass = room['currentClass'];
    final className = currentClass != null ? currentClass['className'] : null;

    final statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showClassroomDetails(context, room),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bar
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
                        // Icon Box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isLab ? Icons.science_rounded : (isOccupied ? Icons.door_front_door : Icons.meeting_room_outlined),
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOccupied ? 'OCCUPIED' : 'AVAILABLE',
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(roomName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    const SizedBox(height: 4),
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLab ? const Color(0xFFFF9800).withOpacity(0.15) : const Color(0xFF00ACC1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isLab ? Icons.science_rounded : Icons.class_rounded, size: 11, color: isLab ? const Color(0xFFFF9800) : const Color(0xFF00ACC1)),
                          const SizedBox(width: 3),
                          Text(room['type'] ?? 'Class', style: TextStyle(fontSize: 10, color: isLab ? const Color(0xFFFF9800) : const Color(0xFF00ACC1), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(children: [Icon(Icons.layers, size: 12, color: scheme.onSurfaceVariant), const SizedBox(width: 3), Text(floor, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))]),
                    const SizedBox(height: 3),
                    Row(children: [Icon(Icons.people, size: 12, color: scheme.onSurfaceVariant), const SizedBox(width: 3), Text('$capacity seats', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))]),

                    // Occupant Info (If Occupied)
                    if (isOccupied && className != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          className,
                          style: TextStyle(fontSize: 10, color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
    final roomName = room['name'] ?? 'Unknown';
    final isOccupied = room['isOccupied'] == true;
    final currentClass = room['currentClass'];

    final statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: scheme.onSurfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: Icon(isOccupied ? Icons.door_front_door : Icons.meeting_room_outlined, color: statusColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roomName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(isOccupied ? 'OCCUPIED' : 'AVAILABLE', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.category, 'Type', room['type'] ?? '-', scheme),
            _buildDetailRow(Icons.layers, 'Floor', room['floor'] ?? '-', scheme),
            _buildDetailRow(Icons.people, 'Capacity', '${room['capacity'] ?? 0} seats', scheme),

            if (isOccupied && currentClass != null) ...[
              const Divider(),
              const SizedBox(height: 10),
              Text("Current Occupant", style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary)),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.book, 'Subject', currentClass['subject'] ?? '-', scheme),
              _buildDetailRow(Icons.group, 'Class', currentClass['className'] ?? '-', scheme),
              _buildDetailRow(Icons.person, 'Teacher', currentClass['teacher'] ?? '-', scheme),
            ],

            const SizedBox(height: 24),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(bCtx),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Close', style: TextStyle(fontSize: 16))),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: scheme.onSurface))),
        ],
      ),
    );
  }
}