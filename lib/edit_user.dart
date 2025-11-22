// lib/edit_user_by_email.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart'; // uses ApiService.uploadAvatarByEmail and ApiService.baseUrl

class EditUserByEmailPage extends StatefulWidget {
  const EditUserByEmailPage({Key? key}) : super(key: key);

  @override
  State<EditUserByEmailPage> createState() => _EditUserByEmailPageState();
}

class _EditUserByEmailPageState extends State<EditUserByEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

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
    final picked = await showDatePicker(context: context, initialDate: dob ?? DateTime(2000), firstDate: DateTime(1950), lastDate: now);
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
      // Note: ApiService.uploadAvatarByEmail currently doesn't provide progress; it returns a Map.
      await ApiService.uploadAvatarByEmail(email: email, profilePath: _profileFile!.path);
      // If you want progress, we can update ApiService to use dio or a streamed request.
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
  /// Backend endpoint expected: PUT (or POST) {baseUrl}/api/users/update-by-email
  /// Body: { email: <email>, <field1>: value, ... }
  Future<void> _sendFieldUpdates() async {
    // Gather only provided fields into a payload
    final Map<String, dynamic> payload = {'email': email};

    if (name.isNotEmpty) payload['name'] = name;
    if (password.isNotEmpty) payload['password'] = password;
    if (rollNo.isNotEmpty) payload['rollNo'] = rollNo;
    if (branch.isNotEmpty) payload['branch'] = branch;
    if (semester != null) payload['semester'] = semester;
    if (section.isNotEmpty) payload['section'] = section;
    if (role.isNotEmpty) payload['role'] = role;
    if (dob != null) payload['dob'] = dob!.toIso8601String();

    // If there's nothing to update (and no image), we return
    if (payload.keys.length <= 1) return;

    final url = Uri.parse('${ApiService.baseUrl}/api/users/update-by-email');
    final headers = <String, String>{'Content-Type': 'application/json'};

    final res = await http.put(url, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 200) {
      // success
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
    // email must be provided
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User email is required')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      // 1) If image present → upload image first via email-based endpoint
      if (_profileFile != null) {
        await _uploadImageIfPresent();
      }

      // 2) Send other field updates
      await _sendFieldUpdates();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully')));
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit User (by email)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Email field (identifier)
          TextFormField(
            decoration: const InputDecoration(labelText: 'User Email (required)'),
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => email = v.trim().toLowerCase(),
          ),
          const SizedBox(height: 12),

          // Profile preview
          if (_profileFile != null)
            SizedBox(height: 150, child: Image.file(_profileFile!, fit: BoxFit.cover))
          else
            SizedBox(height: 150, child: Center(child: Text('No new profile selected'))),

          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(onPressed: _pickImageFromGallery, icon: const Icon(Icons.photo), label: const Text('Gallery')),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: _pickImageFromCamera, icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
          ]),

          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Full name'), onSaved: (v) => name = v?.trim() ?? ''),
              TextFormField(decoration: const InputDecoration(labelText: 'Password (leave blank to keep)'), obscureText: true, onSaved: (v) => password = v ?? ''),
              Row(children: [
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Roll No'), onSaved: (v) => rollNo = v?.trim() ?? '')),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Branch'), onSaved: (v) => branch = v?.trim() ?? '')),
              ]),
              Row(children: [
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Semester'), keyboardType: TextInputType.number, onSaved: (v) => semester = (v == null || v.isEmpty) ? null : int.tryParse(v))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Section'), onSaved: (v) => section = v?.trim() ?? '')),
              ]),
              ListTile(title: Text(dob == null ? 'Select DOB' : DateFormat.yMMMd().format(dob!)), trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDob)),
              const SizedBox(height: 12),
              if (_isSubmitting)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.save), label: const Text('Update User')),
            ]),
          ),
        ]),
      ),
    );
  }
}
