import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String dept;
  final String section;
  final bool isDark;
  final String? initialPhotoUrl;

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
    this.initialPhotoUrl,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  late bool _localIsDark;
  late String? profileImage;

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _email = widget.userEmail;
    _localIsDark = widget.isDark;
    profileImage = widget.initialPhotoUrl;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      setState(() => _localIsDark = widget.isDark);
    }
    if (oldWidget.initialPhotoUrl != widget.initialPhotoUrl) {
      setState(() => profileImage = widget.initialPhotoUrl);
    }
  }

  /// ✅ FIXED IMAGE HELPER
  /// Returns an ImageProvider if a valid link/file exists, otherwise returns NULL.
  /// This prevents the "Asset not found" crash.
  ImageProvider? _getSafeImageProvider(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();

    // 1. Network Image
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    // 2. Local File
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (e) {
      // Ignore errors, return null
    }

    return null;
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated')));
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
                const SizedBox(height: 8),
                TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
                const SizedBox(height: 8),
                TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        );
      },
    );

    if (ok != true) return;

    final current = currentCtrl.text.trim();
    final nw = newCtrl.text.trim();
    final confirm = confirmCtrl.text.trim();

    if (current.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter current password')));
      return;
    }
    if (nw.length < 8) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 8 characters')));
      return;
    }
    if (nw != confirm) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }

    String baseUrl = 'http://localhost:4000';
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        //baseUrl = 'http://10.0.2.2:4000';
        baseUrl = 'http://127.0.0.1:4000';
      }
    } catch (_) {}

    final uri = Uri.parse('$baseUrl/api/user/change-password');

    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating password...'), duration: Duration(seconds: 1)));

      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': _email, 'currentPassword': current, 'newPassword': nw}));

      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
      } else {
        String errorMsg = 'Failed to change password';
        try {
          final body = jsonDecode(resp.body);
          errorMsg = body['error'] ?? body['message'] ?? errorMsg;
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _infoChip({required BuildContext context, required IconData icon, required String text, double? maxWidth, EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6), bool showTooltip = false}) {
    const maroon = Color(0xFFA4123F);
    final effectiveMax = maxWidth ?? MediaQuery.of(context).size.width * 0.6;
    final child = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: effectiveMax),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
    );

    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(color: maroon, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))]),
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
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3))]),
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
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.brightness_6, color: cs.onPrimaryContainer)),
          const SizedBox(width: 12),
          Expanded(child: Text(_localIsDark ? 'Dark Mode' : 'Light Mode', style: const TextStyle(fontWeight: FontWeight.w700))),
          Switch.adaptive(value: _localIsDark, onChanged: (value) {
            setState(() => _localIsDark = value);
            widget.onToggleTheme?.call(value);
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deptSection = '${widget.dept} - ${widget.section}';

    // Calculate the image provider once (safely)
    final imageProvider = _getSafeImageProvider(profileImage);

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

                // ✅ UPDATED: Safe Avatar Code
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24, // Light background for transparency
                  // If provider is null (no image), backgroundImage is null
                  backgroundImage: imageProvider,
                  // If provider is null, show the Icon as a child
                  child: imageProvider == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_name, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _infoChip(context: context, icon: Icons.badge, text: deptSection, maxWidth: MediaQuery.of(context).size.width * 0.45),
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