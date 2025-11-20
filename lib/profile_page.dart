// lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String dept;
  final String section;
  final bool isDark;
  final ValueChanged<bool>? onToggleTheme;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateEmail;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.dept,
    required this.section,
    this.isDark = false,
    this.onToggleTheme,
    this.onUpdateName,
    this.onUpdateEmail,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  late bool _localIsDark; // local copy for immediate UI response

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _email = widget.userEmail;
    _localIsDark = widget.isDark;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      _localIsDark = widget.isDark;
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _name = ctrl.text.trim());
      widget.onUpdateName?.call(_name);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated')));
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    // 1. Show the Dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration:
                  const InputDecoration(labelText: 'Current password'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                  const InputDecoration(labelText: 'Confirm new password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final current = currentCtrl.text.trim();
    final nw = newCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    // 2. Client-side Validation
    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter current password')));
      return;
    }
    if (nw.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('New password must be at least 8 characters')));
      return;
    }
    if (nw != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match')));
      return;
    }

    // 3. Prepare the URL (Fix for Android Emulator)
    // Use 10.0.2.2 for Android emulator, localhost for iOS/Web
    String baseUrl = 'http://localhost:4000';
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        baseUrl = 'http://127.0.0.1:4000';
        //baseUrl = 'http://10.0.2.2:4000';
      }
    } catch (e) {
      // Fallback if platform check fails
      baseUrl = 'http://localhost:4000';
    }

    final uri = Uri.parse('$baseUrl/api/user/change-password');

    // 4. Send Request
    try {
      // Show a loading indicator (optional but good for UX)
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updating password...'), duration: Duration(seconds: 1)));

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_TOKEN_HERE', // Uncomment if using JWT
        },
        body: jsonEncode({
          'email': _email, // We must send the email to identify the user
          'currentPassword': current,
          'newPassword': nw,
        }),
      );

      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password changed successfully!')));
      } else {
        if (!mounted) return;
        // Try to parse error message from backend
        String errorMsg = 'Failed to change password';
        try {
          final body = jsonDecode(resp.body);
          errorMsg = body['error'] ?? body['message'] ?? errorMsg;
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMsg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connection Error: $e'), backgroundColor: Colors.red));
    }
  }
  Future<void> _editEmail() async {
    final ctrl = TextEditingController(text: _email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Email'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _email = ctrl.text.trim());
      widget.onUpdateEmail?.call(_email);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated')));
    }
  }

  /// Shorten a long string by keeping the start and end, inserting '...'
  String shortenEmailDomain(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex == -1) return email;

    final user = email.substring(0, atIndex); // before @
    final domain = email.substring(atIndex + 1); // after @

    // Show only first 2 letters of domain
    // Example: am.students.amrita.edu → am...
    final shortDomain = domain.length > 2 ? domain.substring(0, 2) + "..." : domain;

    return "$user@$shortDomain";
  }


  /// Chip builder with constrained width + ellipsis
  Widget _infoChip({
    required BuildContext context,
    required IconData icon,
    required String text,
    double? maxWidth,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    bool showTooltip = false,
  }) {
    const maroon = Color(0xFFA4123F); // Your custom color
    final effectiveMax = maxWidth ?? MediaQuery.of(context).size.width * 0.6;

    // shorten only domain part
    final displayText = text.length > 1 ? shortenEmailDomain(text) : text;

    final child = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: effectiveMax),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),     // white icon
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,                      // white text
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: maroon,                                     // maroon background
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );

    return showTooltip ? Tooltip(message: text, child: chip) : chip;
  }


  Widget _actionTile(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
          BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3))
        ]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: cs.onPrimaryContainer)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }

  Widget _themeTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 12 * 3) / 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
          BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3))
        ]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.brightness_6, color: cs.onPrimaryContainer)),
            const SizedBox(width: 12),
            Expanded(child: Text(_localIsDark ? 'Dark Mode' : 'Light Mode', style: const TextStyle(fontWeight: FontWeight.w700))),
            Switch.adaptive(
              value: _localIsDark,
              onChanged: (value) {
                setState(() => _localIsDark = value);
                widget.onToggleTheme?.call(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deptSection = '${widget.dept} - ${widget.section}';

    return ListView(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const CircleAvatar(radius: 40, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3")),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_name, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      // dept-section chip (shorter width)
                      _infoChip(context: context, icon: Icons.badge, text: deptSection, maxWidth: MediaQuery.of(context).size.width * 0.45),
                      // email chip: show tooltip with full email and ellipsis in chip
                      _infoChip(context: context, icon: Icons.email, text: _email, maxWidth: MediaQuery.of(context).size.width * 0.55, showTooltip: true),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            _actionTile(context, icon: Icons.lock, label: 'Change Password', onTap: _changePassword),
            _actionTile(context, icon: Icons.edit, label: 'Edit Name', onTap: _editName),
            _actionTile(context, icon: Icons.email, label: 'Edit Email', onTap: _editEmail),
            _themeTile(context),
          ]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
