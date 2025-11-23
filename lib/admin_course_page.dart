import 'dart:io';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart'; // Contains Course and TeacherSearchResult models

/// Local test image path as requested for testing
const String _localTestImagePath = '/mnt/data/ccc6d016-2a67-40cd-aedd-aa3fc7a50e4f.jpg';

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

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  // This controller is used for the visual text input in the Autocomplete
  // and acts as a fallback if the admin types a name manually.
  final TextEditingController _facultyTextController = TextEditingController();

  // Selected Faculty Data
  String _selectedFacultyName = '';
  String _selectedFacultyId = '';
  String _selectedFacultyImage = '';
  String _selectedFacultyDept = '';

  // Color Picker State
  Color _selectedColor = const Color(0xFF0D6EFD); // Default Blue
  String _selectedColorHex = '#0D6EFD';

  // Dropdown Options
  final List<String> _branches = ['CSE', 'EEE', 'MECH', 'CIVIL', 'AIE', 'ECE'];
  final List<String> _semesters = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  // Color Palette
  final List<String> _palette = [
    '#0D6EFD', '#20C997', '#FFA927', '#8A63D2', '#EF476F',
    '#198754', '#DC3545', '#6610F2', '#FD7E14', '#0DCAF0'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _facultyTextController.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCourse() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if we have a name (either selected or typed manually)
    final facultyNameToSend = _selectedFacultyName.isNotEmpty
        ? _selectedFacultyName
        : _facultyTextController.text.trim();

    if (facultyNameToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or enter a faculty name'))
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.addCourse({
        'courseName': _nameController.text.trim(),
        'courseCode': _codeController.text.trim(),
        'branch': _selectedBranch,
        'semester': _selectedSemester,
        'section': _selectedSection,
        'color': _selectedColorHex,
        // Faculty Details
        'facultyName': facultyNameToSend,
        'facultyId': _selectedFacultyId,     // Empty if typed manually
        'facultyImage': _selectedFacultyImage, // Empty if typed manually
        'facultyDept': _selectedFacultyDept,   // Empty if typed manually
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course Added Successfully!'), backgroundColor: Colors.green),
        );
      }

      // Reset Form
      _nameController.clear();
      _codeController.clear();
      _facultyTextController.clear();
      setState(() {
        _selectedFacultyName = '';
        _selectedFacultyId = '';
        _selectedFacultyImage = '';
        _selectedFacultyDept = '';
        _selectedColor = const Color(0xFF0D6EFD);
        _selectedColorHex = '#0D6EFD';
      });

      await _fetchCourses(); // Refresh list

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add course: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Helpers ---

  ImageProvider? _getImageProvider(String? url) {
    // 1. Try Network URL
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    // 2. Try Local Test File (only if it exists)
    try {
      final file = File(_localTestImagePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    // 3. Return null (will trigger fallback icon)
    return null;
  }

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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Class Selector
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
                          Expanded(child: _buildDropdown('Branch', _branches, _selectedBranch, (v) { setState(() => _selectedBranch = v!); _fetchCourses(); })),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDropdown('Semester', _semesters, _selectedSemester, (v) { setState(() => _selectedSemester = v!); _fetchCourses(); })),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDropdown('Section', _sections, _selectedSection, (v) { setState(() => _selectedSection = v!); _fetchCourses(); })),
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
                                decoration: const InputDecoration(labelText: 'Code (e.g. MAT101)', border: OutlineInputBorder(), isDense: true),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Faculty Autocomplete & Color Picker
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Autocomplete<TeacherSearchResult>(
                                displayStringForOption: (TeacherSearchResult option) => option.name,
                      // In lib/admin_course_page.dart

                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<TeacherSearchResult>.empty();
                        }
                        try {
                          // 🔍 Print what we are searching for
                          print("Searching for: ${textEditingValue.text}");

                          final results = await ApiService.searchTeachers(textEditingValue.text);

                          // 🔍 Print how many results we got
                          print("Results found: ${results.length}");

                          return results;
                        } catch (e) {
                          // 🚨 THIS IS CRITICAL: Print the error so we can see it in the logs
                          print("❌ Error searching faculty: $e");
                          return const Iterable<TeacherSearchResult>.empty();
                        }
                      },
                                onSelected: (TeacherSearchResult selection) {
                                  setState(() {
                                    _selectedFacultyName = selection.name;
                                    _selectedFacultyId = selection.id;
                                    _selectedFacultyImage = selection.image ?? '';
                                    _selectedFacultyDept = selection.dept;
                                    _facultyTextController.text = selection.name; // Visual sync
                                  });
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  // Sync the internal controller with our external one if it's empty (first load)
                                  if (controller.text.isEmpty && _facultyTextController.text.isNotEmpty) {
                                    controller.text = _facultyTextController.text;
                                  }

                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Search Faculty',
                                      hintText: 'Type to search...',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: _selectedFacultyName.isNotEmpty
                                          ? const Icon(Icons.check_circle, color: Colors.green)
                                          : const Icon(Icons.person_search),
                                      suffixIcon: _selectedFacultyName.isNotEmpty
                                          ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          controller.clear();
                                          setState(() {
                                            _selectedFacultyName = '';
                                            _selectedFacultyId = '';
                                            _selectedFacultyImage = '';
                                            _selectedFacultyDept = '';
                                            _facultyTextController.clear();
                                          });
                                        },
                                      )
                                          : null,
                                    ),
                                    onChanged: (val) {
                                      // If user modifies text after selection, clear the "Selected Object"
                                      // allowing them to type a manual name if needed.
                                      if (_selectedFacultyName.isNotEmpty && val != _selectedFacultyName) {
                                        setState(() {
                                          _selectedFacultyName = '';
                                          _selectedFacultyId = '';
                                          _selectedFacultyImage = '';
                                          _selectedFacultyDept = '';
                                        });
                                      }
                                      _facultyTextController.text = val;
                                    },
                                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4.0,
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width - 120, // Dynamic width
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final option = options.elementAt(index);
                                            final imageProvider = _getImageProvider(option.image);

                                            return ListTile(
                                              leading: CircleAvatar(
                                                backgroundImage: imageProvider,
                                                child: imageProvider == null
                                                    ? Text(option.name.isNotEmpty ? option.name[0] : '?')
                                                    : null,
                                              ),
                                              title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: Text('Dept: ${option.dept}'),
                                              onTap: () => onSelected(option),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Color Picker
                            Column(
                              children: [
                                const Text('Color', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _pickColor,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: _selectedColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300),
                                        boxShadow: [BoxShadow(color: _selectedColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))]
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Text(
                              'Tip: Select a faculty from the list to link their profile photo.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)
                          ),
                        ),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _addCourse,
                            icon: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.add),
                            label: const Text('Add Course'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              Text('Existing Courses (${_courses.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),

              _isLoading && _courses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _courses.isEmpty
                  ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('No courses found for $_selectedBranch $_selectedSemester $_selectedSection', style: const TextStyle(color: Colors.grey)),
                  )
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courses.length,
                itemBuilder: (ctx, i) {
                  final c = _courses[i];
                  // Use stored faculty image if available, else initial
                  final hasImage = c.facultyImage.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _hexToColor(c.color),
                        backgroundImage: hasImage ? NetworkImage(c.facultyImage) : null,
                        child: !hasImage
                            ? Text((c.courseCode.isNotEmpty ? c.courseCode[0] : '?'), style: const TextStyle(color: Colors.white))
                            : null,
                      ),
                      title: Text('${c.courseName} (${c.courseCode})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Faculty: ${c.facultyName}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // Placeholder for Edit/Delete action
                        },
                      ),
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
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}