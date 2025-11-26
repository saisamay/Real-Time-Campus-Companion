import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  Key _searchKey = UniqueKey();

  String? _selectedUserId;
  String? _currentProfileUrl;

  // --- CONTROLLERS ---
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _rollNoCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  // Merged: Controller for Cabin Room
  final _cabinCtrl = TextEditingController();

  // State Variables
  String role = 'student';
  DateTime? dob;
  File? _newProfileFile;
  bool _isSubmitting = false;

  // Options
  final List<String> _semesterOptions = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
  String? _selectedSemester;
  final List<String> _roleOptions = ['student', 'classrep', 'teacher', 'admin', 'staff'];

  // Role Helpers
  bool get isStudent => role == 'student' || role == 'classrep';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';

  bool get enableRollNo => isStudent || isAdmin;
  bool get enableBranch => isStudent || isTeacher || isAdmin;
  bool get enableSemester => isStudent || isAdmin;
  bool get enableSection => isStudent || isAdmin;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _rollNoCtrl.dispose();
    _branchCtrl.dispose();
    _semesterCtrl.dispose();
    _sectionCtrl.dispose();
    _cabinCtrl.dispose(); // Dispose cabin controller
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (f != null) setState(() => _newProfileFile = File(f.path));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (f != null) setState(() => _newProfileFile = File(f.path));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => dob = picked);
  }

  void _populateForm(Map<String, dynamic> user) {
    setState(() {
      _selectedUserId = user['_id'];

      // Update Controllers directly
      _nameCtrl.text = user['name'] ?? '';
      _emailCtrl.text = user['email'] ?? '';
      _rollNoCtrl.text = user['rollNo'] ?? '';
      _branchCtrl.text = user['branch'] ?? '';
      _sectionCtrl.text = user['section'] ?? '';

      // Merged: Populate Cabin Room
      _cabinCtrl.text = user['cabinRoom'] ?? '';

      _passwordCtrl.clear();

      role = user['role'] ?? 'student';
      String sem = user['semester'] ?? '';

      if (user['dob'] != null) {
        try { dob = DateTime.parse(user['dob']); } catch (_) { dob = null; }
      } else { dob = null; }

      if (_semesterOptions.contains(sem)) {
        _selectedSemester = sem;
      } else {
        _selectedSemester = null;
      }

      if (user['profile'] != null && user['profile']['url'] != null) {
        _currentProfileUrl = user['profile']['url'];
      } else {
        _currentProfileUrl = null;
      }
      _newProfileFile = null;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUserId = null;
      _searchKey = UniqueKey();
      _nameCtrl.clear();
      _emailCtrl.clear();
      _rollNoCtrl.clear();
      _branchCtrl.clear();
      _sectionCtrl.clear();
      _passwordCtrl.clear();
      _cabinCtrl.clear(); // Clear cabin
      _selectedSemester = null;
      _newProfileFile = null;
      _currentProfileUrl = null;
    });
  }

  Future<void> _updateUser() async {
    if (_selectedUserId == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      String sendRoll = enableRollNo ? _rollNoCtrl.text.trim() : '';
      String sendBranch = enableBranch ? _branchCtrl.text.trim() : '';
      String sendSem = enableSemester ? (_selectedSemester ?? '') : '';
      String sendSec = enableSection ? _sectionCtrl.text.trim() : '';

      // Merged: Logic to handle Cabin Room updates
      // If not teacher, send empty string to clear it in DB
      String sendCabin = isTeacher ? _cabinCtrl.text.trim() : '';

      await ApiService.updateUserById(
        id: _selectedUserId!,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        dob: dob,
        role: role,
        rollNo: sendRoll,
        semester: sendSem,
        section: sendSec,
        branch: sendBranch,
        cabinRoom: sendCabin, // Pass to API
        profilePath: _newProfileFile?.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Updated Successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteUser() async {
    if (_selectedUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${_emailCtrl.text}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      try {
        await ApiService.deleteUser(_selectedUserId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Deleted'), backgroundColor: Colors.green));
          _clearSelection();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete Failed: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return Scaffold(
      appBar: AppBar(title: const Text('Edit / Delete User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Bar
            Autocomplete<Map<String, dynamic>>(
              key: _searchKey,
              displayStringForOption: (option) => option['email'] ?? '',
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                try {
                  final results = await ApiService.searchUsers(textEditingValue.text);
                  return results.cast<Map<String, dynamic>>();
                } catch (e) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
              },
              onSelected: (Map<String, dynamic> selection) {
                _populateForm(selection);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search User by Email',
                    hintText: 'Start typing email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: textEditingController.text.isNotEmpty || _selectedUserId != null
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        textEditingController.clear();
                        _clearSelection();
                      },
                    )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(option['name'] ?? 'Unknown'),
                            subtitle: Text(option['email'] ?? ''),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            if (_selectedUserId == null)
              const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.person_search, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Search and select a user above to edit details.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                            child: ClipOval(
                              child: _newProfileFile != null
                                  ? Image.file(_newProfileFile!, fit: BoxFit.cover, width: 130, height: 130)
                                  : (_currentProfileUrl != null
                                  ? Image.network(_currentProfileUrl!, fit: BoxFit.cover, width: 130, height: 130, errorBuilder: (c,o,s) => const Icon(Icons.person, size: 70))
                                  : Icon(Icons.person, size: 70, color: isDark ? Colors.grey[600] : Colors.grey[500])),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.teal, border: Border.all(color: isDark ? Colors.grey[900]! : Colors.white, width: 3)),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Role
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.admin_panel_settings_outlined), border: OutlineInputBorder()),
                      value: role,
                      items: _roleOptions.map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase()))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() { role = val; });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Personal Info
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(labelText: 'New Password (Optional)', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder(), hintText: 'Leave blank to keep current'),
                    ),
                    const SizedBox(height: 15),

                    // RollNo & Section
                    Row(
                      children: [
                        Expanded(child: AbsorbPointer(absorbing: !enableRollNo, child: Opacity(opacity: enableRollNo ? 1 : 0.5, child: TextFormField(
                          controller: _rollNoCtrl,
                          decoration: InputDecoration(labelText: 'Roll No', border: const OutlineInputBorder(), filled: !enableRollNo, fillColor: !enableRollNo ? disabledColor : null),
                        )))),
                        const SizedBox(width: 10),
                        Expanded(child: AbsorbPointer(absorbing: !enableSection, child: Opacity(opacity: enableSection ? 1 : 0.5, child: TextFormField(
                          controller: _sectionCtrl,
                          decoration: InputDecoration(labelText: 'Section', border: const OutlineInputBorder(), filled: !enableSection, fillColor: !enableSection ? disabledColor : null),
                        )))),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Semester & Branch
                    Row(
                      children: [
                        Expanded(child: AbsorbPointer(absorbing: !enableSemester, child: Opacity(opacity: enableSemester ? 1 : 0.5, child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: 'Semester', border: const OutlineInputBorder(), filled: !enableSemester, fillColor: !enableSemester ? disabledColor : null),
                          value: _selectedSemester,
                          items: _semesterOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: enableSemester ? (v) => setState(() { _selectedSemester = v; }) : null,
                        )))),
                        const SizedBox(width: 10),
                        Expanded(child: AbsorbPointer(absorbing: !enableBranch, child: Opacity(opacity: enableBranch ? 1 : 0.5, child: TextFormField(
                          controller: _branchCtrl,
                          decoration: InputDecoration(labelText: 'Branch', border: const OutlineInputBorder(), filled: !enableBranch, fillColor: !enableBranch ? disabledColor : null),
                        )))),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- Merged: Teacher Cabin Field ---
                    if (isTeacher)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: TextFormField(
                          controller: _cabinCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cabin Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.room),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required for teacher' : null,
                        ),
                      ),

                    // DOB
                    InkWell(
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                        child: Text(dob == null ? 'Select Date' : DateFormat.yMMMd().format(dob!), style: TextStyle(color: dob == null ? Colors.grey : (isDark ? Colors.white : Colors.black))),
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (_isSubmitting)
                      const CircularProgressIndicator()
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _updateUser,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                              child: const Text('Update User', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _deleteUser,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                              child: const Text('Delete User', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}