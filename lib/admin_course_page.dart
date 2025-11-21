import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart'; // Ensure this file exists from Step 1

class AdminCoursePage extends StatefulWidget {
  const AdminCoursePage({super.key});

  @override
  State<AdminCoursePage> createState() => _AdminCoursePageState();
}

class _AdminCoursePageState extends State<AdminCoursePage> {
  final _formKey = GlobalKey<FormState>();

  // --- State Variables ---
  bool _isLoading = false;
  List<Course> _courses = [];

  // Selectors (Default values)
  String _selectedBranch = 'CSE';
  String _selectedSemester = 'S5';
  String _selectedSection = 'A';

  // Text Controllers for New Course
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _facultyController = TextEditingController();

  // Color Picker State
  Color _selectedColor = const Color(0xFF0D6EFD); // Default Blue
  String _selectedColorHex = '#0D6EFD';

  // Dropdown Options
  final List<String> _branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'AIE', 'ECE'];
  final List<String> _semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  // Color Palette for Picker
  final List<String> _palette = [
    '#0D6EFD', '#20C997', '#FFA927', '#8A63D2', '#EF476F',
    '#198754', '#DC3545', '#6610F2', '#FD7E14', '#0DCAF0'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses(); // Load courses for default selection
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  // --- API Calls ---

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await ApiService.getCourses(
          _selectedBranch,
          _selectedSemester,
          _selectedSection
      );
      setState(() => _courses = courses);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading courses: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.addCourse({
        'courseName': _nameController.text.trim(),
        'courseCode': _codeController.text.trim(),
        'facultyName': _facultyController.text.trim(),
        'branch': _selectedBranch,
        'semester': _selectedSemester,
        'section': _selectedSection,
        'color': _selectedColorHex,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course Added Successfully!'), backgroundColor: Colors.green),
      );

      // Clear form and refresh list
      _nameController.clear();
      _codeController.clear();
      _facultyController.clear();
      _fetchCourses();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add course: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Helper: Color Picker ---
  void _pickColor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick Course Color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _palette.map((hex) {
            final color = _hexToColor(hex);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColorHex = hex;
                  _selectedColor = color;
                });
                Navigator.pop(ctx);
              },
              child: CircleAvatar(
                backgroundColor: color,
                radius: 18,
                child: _selectedColorHex == hex
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCourses,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Class Selector Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown('Branch', _branches, _selectedBranch, (val) {
                              setState(() => _selectedBranch = val!);
                              _fetchCourses();
                            }),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdown('Semester', _semesters, _selectedSemester, (val) {
                              setState(() => _selectedSemester = val!);
                              _fetchCourses();
                            }),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdown('Section', _sections, _selectedSection, (val) {
                              setState(() => _selectedSection = val!);
                              _fetchCourses();
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Add Course Form
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add New Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),

                        // Course Name & Code
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Course Name', border: OutlineInputBorder(), isDense: true),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(labelText: 'Code (MAT101)', border: OutlineInputBorder(), isDense: true),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Faculty & Color
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _facultyController,
                                decoration: const InputDecoration(labelText: 'Faculty Full Name', border: OutlineInputBorder(), isDense: true),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _pickColor,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Icon(Icons.color_lens, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _addCourse,
                            icon: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.add),
                            label: const Text('Add Course'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // 3. Existing Courses List
              Text('Existing Courses (${_courses.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),

              _isLoading && _courses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _courses.isEmpty
                  ? const Center(child: Text('No courses found for this class.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courses.length,
                itemBuilder: (ctx, i) {
                  final c = _courses[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _hexToColor(c.color),
                        child: Text(
                            c.courseCode.substring(0, 1),
                            style: const TextStyle(color: Colors.white)
                        ),
                      ),
                      title: Text('${c.courseName} (${c.courseCode})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Faculty: ${c.facultyName}'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}