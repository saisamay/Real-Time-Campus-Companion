// lib/edit_user_by_email.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class EditUserByEmailPage extends StatefulWidget {
  const EditUserByEmailPage({Key? key}) : super(key: key);

  @override
  State<EditUserByEmailPage> createState() => _EditUserByEmailPageState();
}

class _EditUserByEmailPageState extends State<EditUserByEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _emailController = TextEditingController();

  // Required identifier
  String email = '';

  // editable fields
  String name = '';
  String password = '';
  String rollNo = '';
  String branch = '';
  int? semester;
  String section = '';
  String role = 'student';
  DateTime? dob;

  // optional new profile image chosen locally
  File? _profileFile;

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  double _imageUploadProgress = 0.0;

  // For autocomplete
  List<String> _allUserEmails = [];
  List<String> _filteredEmails = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _fetchAllUserEmails();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Fetch all user emails from backend for autocomplete
  Future<void> _fetchAllUserEmails() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/users/emails');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _allUserEmails = data.map((e) => e.toString()).toList();
          });
        }
      }
    } catch (e) {
      // Silent fail - autocomplete just won't work
      debugPrint('Failed to fetch user emails: $e');
    }
  }

  /// Filter emails based on input
  void _filterEmails(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredEmails = [];
        _showSuggestions = false;
      });
      return;
    }

    final filtered = _allUserEmails
        .where((email) => email.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      _filteredEmails = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f == null) return;
    setState(() => _profileFile = File(f.path));
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (f == null) return;
    setState(() => _profileFile = File(f.path));
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

  /// Sends the profile image first (if any), using ApiService.uploadAvatarByEmail
  Future<void> _uploadImageIfPresent() async {
    if (_profileFile == null) return;
    setState(() {
      _isUploadingImage = true;
      _imageUploadProgress = 0.0;
    });

    try {
      await ApiService.uploadAvatarByEmail(
        email: email,
        profilePath: _profileFile!.path,
      );
    } catch (e) {
      rethrow;
    } finally {
      setState(() {
        _isUploadingImage = false;
        _imageUploadProgress = 0.0;
      });
    }
  }

  /// Sends the other updates (non-image) to backend using email-based JSON endpoint.
  Future<void> _sendFieldUpdates() async {
    final Map<String, dynamic> payload = {'email': email};

    if (name.isNotEmpty) payload['name'] = name;
    if (password.isNotEmpty) payload['password'] = password;
    if (rollNo.isNotEmpty) payload['rollNo'] = rollNo;
    if (branch.isNotEmpty) payload['branch'] = branch;
    if (semester != null) payload['semester'] = semester;
    if (section.isNotEmpty) payload['section'] = section;
    if (role.isNotEmpty) payload['role'] = role;
    if (dob != null) payload['dob'] = dob!.toIso8601String();

    if (payload.keys.length <= 1) return;

    final url = Uri.parse('${ApiService.baseUrl}/api/users/update-by-email');
    final headers = <String, String>{'Content-Type': 'application/json'};

    final res = await http.put(url, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 200) {
      return;
    } else {
      String msg = res.body;
      try {
        final body = jsonDecode(res.body);
        if (body is Map && (body['message'] != null || body['error'] != null)) {
          msg = body['message'] ?? body['error'] ?? res.body;
        }
      } catch (_) {}
      throw Exception('Update failed (${res.statusCode}): $msg');
    }
  }

  Future<void> _submit() async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email is required')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      if (_profileFile != null) {
        await _uploadImageIfPresent();
      }

      await _sendFieldUpdates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteUser() async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email is required')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete the user with email "$email"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/users/delete-by-email');
      final headers = <String, String>{'Content-Type': 'application/json'};
      final payload = {'email': email};

      final res = await http.delete(url, headers: headers, body: jsonEncode(payload));

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        String msg = res.body;
        try {
          final body = jsonDecode(res.body);
          if (body is Map && (body['message'] != null || body['error'] != null)) {
            msg = body['message'] ?? body['error'] ?? res.body;
          }
        } catch (_) {}
        throw Exception('Delete failed (${res.statusCode}): $msg');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit User (by email)')),
      body: GestureDetector(
        onTap: () {
          // Hide suggestions when tapping outside
          setState(() => _showSuggestions = false);
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Email field with autocomplete
              Stack(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'User Email (required)',
                      suffixIcon: _emailController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _emailController.clear();
                          setState(() {
                            email = '';
                            _showSuggestions = false;
                          });
                        },
                      )
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) {
                      setState(() {
                        email = v.trim().toLowerCase();
                      });
                      _filterEmails(v);
                    },
                    onTap: () {
                      if (_emailController.text.isNotEmpty) {
                        _filterEmails(_emailController.text);
                      }
                    },
                  ),
                  // Suggestions dropdown
                  if (_showSuggestions)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _filteredEmails.length,
                            itemBuilder: (context, index) {
                              final suggestedEmail = _filteredEmails[index];
                              return InkWell(
                                onTap: () {
                                  _emailController.text = suggestedEmail;
                                  setState(() {
                                    email = suggestedEmail;
                                    _showSuggestions = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark
                                            ? Colors.grey[800]!
                                            : Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    suggestedEmail,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Profile preview - WhatsApp style circular avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                      child: ClipOval(
                        child: _profileFile != null
                            ? Image.file(
                          _profileFile!,
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                        )
                            : Icon(
                          Icons.person,
                          size: 70,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // Show bottom sheet with camera/gallery options
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt, color: Colors.teal),
                                    title: const Text('Camera'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImageFromCamera();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library, color: Colors.teal),
                                    title: const Text('Gallery'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImageFromGallery();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal,
                            border: Border.all(
                              color: isDark ? Colors.grey[900]! : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Full name'),
                      onSaved: (v) => name = v?.trim() ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Password (leave blank to keep)',
                      ),
                      obscureText: true,
                      onSaved: (v) => password = v ?? '',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Roll No'),
                            onSaved: (v) => rollNo = v?.trim() ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Branch'),
                            onSaved: (v) => branch = v?.trim() ?? '',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Semester'),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => semester =
                            (v == null || v.isEmpty) ? null : int.tryParse(v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Section'),
                            onSaved: (v) => section = v?.trim() ?? '',
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      title: Text(
                        dob == null ? 'Select DOB' : DateFormat.yMMMd().format(dob!),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _pickDob,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons - Update and Delete side by side
                    if (_isSubmitting)
                      const CircularProgressIndicator()
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.save),
                              label: const Text('Update User'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _deleteUser,
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete User'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: isDark ? Colors.red[700] : Colors.red,
                                foregroundColor: Colors.white,
                              ),
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
      ),
    );
  }
}