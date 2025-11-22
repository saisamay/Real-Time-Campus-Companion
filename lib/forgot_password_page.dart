// lib/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // add intl to pubspec if not present
import 'api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  bool _loading = false;

  // show date picker and populate DOB field (YYYY-MM-DD)
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 16, now.month, now.day);
    final first = DateTime(1900);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now,
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      _dobCtrl.text = formatted;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final dob = _dobCtrl.text.trim(); // expected YYYY-MM-DD

    setState(() => _loading = true);
    try {
      final res = await ApiService.forgotPassword(email: email, dob: dob);
      // backend returns { ok: true, message: '...' } or error
      final message = res['message'] ?? 'Temporary password sent if the details matched.';
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // go back to login
            }, child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      final errMsg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Error: $e';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Enter your registered email and date of birth. A temporary password will be emailed if the details match.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Enter your email';
                          if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(s)) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dobCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date of birth',
                          prefixIcon: const Icon(Icons.cake),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: _pickDob,
                          ),
                          hintText: 'YYYY-MM-DD',
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Pick your date of birth';
                          // basic YYYY-MM-DD format check
                          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return 'Use YYYY-MM-DD format';
                          return null;
                        },
                        onTap: _pickDob,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send temporary password'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Back to login'),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
