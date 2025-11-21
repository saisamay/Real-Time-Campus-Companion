// lib/add_user.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart'; // adjust import if needed
import 'package:intl/intl.dart'; // for formatting date if needed

class AddUserPage extends StatefulWidget {
  final ApiService api;
  const AddUserPage({Key? key, required this.api}) : super(key: key);

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String name = '';
  String email = '';
  String password = '';
  String rollNo = '';
  String branch = '';
  String semester = '';
  String section = '';
  String role = 'student';
  DateTime? dob;
  File? _profileFile;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _profileFile = File(file.path);
    });
  }

  Future<void> _pickCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _profileFile = File(file.path);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a profile image')));
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final dobVal = dob ?? DateTime(2000);

      // Call the ApiService.createUserWithProfile which expects a profilePath (String)
      final Map<String, dynamic> result = await ApiService.createUserWithProfile(
        name: name,
        email: email,
        password: password,
        dob: dobVal,
        profilePath: _profileFile!.path,
        role: role,
        rollNo: rollNo,
        semester: semester,
        section: section,
        branch: branch,
      );

      // The ApiService returns a decoded Map. Check for common success shapes:
      // either a top-level 'success' / 'user' / 'message' etc.
      if ((result.containsKey('success') && result['success'] == true) ||
          result.containsKey('user') ||
          result.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully')));
        Navigator.of(context).pop(true); // return success
      } else {
        // fallback: show entire response as error text
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server response: ${result.toString()}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (_profileFile != null)
            SizedBox(
              height: 150,
              child: Image.file(_profileFile!, fit: BoxFit.cover),
            )
          else
            SizedBox(
              height: 150,
              child: Center(child: Text('No profile selected', style: Theme.of(context).textTheme.bodyLarge)),
            ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Gallery')),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: _pickCamera, icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
          ]),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full name'),
                onSaved: (v) => name = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => email = v?.trim().toLowerCase() ?? '',
                validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (v) => password = v ?? '',
                validator: (v) => (v == null || v.length < 6) ? 'Password >= 6 chars' : null,
              ),
              Row(children: [
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
                )
              ]),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Semester'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => semester = v?.trim() ?? '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Section'),
                    onSaved: (v) => section = v?.trim() ?? '',
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              ListTile(
                title: Text(dob == null ? 'Select DOB' : DateFormat.yMMMd().format(dob!)),
                trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDob),
              ),
              const SizedBox(height: 12),
              if (_isSubmitting)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save),
                  label: const Text('Create User'),
                )
            ]),
          )
        ]),
      ),
    );
  }
}
