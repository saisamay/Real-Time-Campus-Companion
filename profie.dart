import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggleTheme;

  // Optional initial values
  final String initialName;
  final String initialEmail;
  final String initialDeptSection;
  final String initialPhotoUrl;

  const ProfilePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.initialName = 'John Doe',
    this.initialEmail = 'student@university.edu',
    this.initialDeptSection = 'CSE-B',
    this.initialPhotoUrl = 'https://images.unsplash.com/photo-1523580846011-d3a5bc25702b?auto=format&fit=crop&w=800&q=80',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String userName = widget.initialName;
  late String userEmail = widget.initialEmail;
  late String userDeptSection = widget.initialDeptSection;
  late String profileImage = widget.initialPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      children: [
        // Header with BTech student image
        Container(
          height: 180,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(profileImage),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.35), BlendMode.darken),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(radius: 36, backgroundImage: NetworkImage(profileImage)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                        Text('$userDeptSection • $userEmail',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(.9))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _changeProfileImage,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                    child: const Text('Change Photo'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Details & actions
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.badge,
                      title: 'Name',
                      subtitle: userName,
                      onTap: () => _editTextField(
                        context,
                        title: 'Edit Name',
                        initial: userName,
                        onSave: (v) => setState(() => userName = v),
                      ),
                    ),
                    _divider(),
                    _settingTile(
                      icon: Icons.apartment,
                      title: 'Department & Section',
                      subtitle: userDeptSection,
                      onTap: () => _editTextField(
                        context,
                        title: 'Edit Department & Section',
                        hint: 'e.g., CSE-B',
                        initial: userDeptSection,
                        onSave: (v) => setState(() => userDeptSection = v),
                      ),
                    ),
                    _divider(),
                    _settingTile(
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: userEmail,
                      onTap: () => _editTextField(
                        context,
                        title: 'Edit Email',
                        initial: userEmail,
                        keyboardType: TextInputType.emailAddress,
                        onSave: (v) => setState(() => userEmail = v),
                      ),
                    ),
                    _divider(),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      value: widget.isDark,
                      onChanged: widget.onToggleTheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.lock,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () => _changePassword(context),
                    ),
                    _divider(),
                    _settingTile(
                      icon: Icons.logout,
                      title: 'Log out',
                      subtitle: 'Sign out of this device',
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- helpers ---
  Widget _settingTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 0, indent: 16, endIndent: 16);

  void _changeProfileImage() {
    setState(() {
      profileImage =
      'https://images.unsplash.com/photo-1525973132219-a04334a76080?auto=format&fit=crop&w=800&q=80';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
  }

  Future<void> _editTextField(
      BuildContext ctx, {
        required String title,
        required String initial,
        String? hint,
        TextInputType? keyboardType,
        required ValueChanged<String> onSave,
      }) async {
    final controller = TextEditingController(text: initial);
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          keyboardType: keyboardType,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          FilledButton(onPressed: () { onSave(controller.text.trim()); Navigator.pop(dCtx); }, child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext ctx) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
            const SizedBox(height: 8),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 8),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text || newCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password changed')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to sign out of this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
    }
  }
}

// use these in main

//// import 'profile_page.dart';
// // ...
// ProfilePage(
//   isDark: widget.isDark,
//   onToggleTheme: widget.onToggleTheme,
// ),