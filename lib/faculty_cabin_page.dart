import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Faculty Model
// ---------------------------------------------------------------------------
class Faculty {
  String id;
  String name;
  String email;
  String password;
  String department;
  String cabinRoom;
  bool availability;
  String profilePhoto;

  Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.department,
    required this.cabinRoom,
    required this.availability,
    required this.profilePhoto,
  });
}

// ---------------------------------------------------------------------------
// Faculty Cabin Page
// ---------------------------------------------------------------------------
class FacultyCabinPage extends StatefulWidget {
  const FacultyCabinPage({Key? key}) : super(key: key);

  @override
  State<FacultyCabinPage> createState() => _FacultyCabinPageState();
}

class _FacultyCabinPageState extends State<FacultyCabinPage> {
  // Sample Data
  List<Faculty> facultyList = [
    Faculty(
      id: '1',
      name: "Dr. Aswathy Mohan",
      email: "aswathymohan@am.amrita.edu",
      password: "software123",
      department: "Computer Science",
      cabinRoom: "S 111C",
      availability: true,
      profilePhoto: "https://collection.cloudinary.com/drlve3044/bda54847bb8b93591a12078885c4957f",
    ),
    Faculty(
      id: '2',
      name: "Dr. Rajesh Kumar",
      email: "rajesh.k@am.amrita.edu",
      password: "password123",
      department: "Mathematics",
      cabinRoom: "M 202",
      availability: false,
      profilePhoto: "",
    ),
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchText = _searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addFaculty() async {
    final Faculty? result = await showDialog<Faculty>(
      context: context,
      builder: (context) => const FacultyDialog(),
    );
    if (result != null) {
      setState(() {
        result.id = DateTime.now().millisecondsSinceEpoch.toString();
        facultyList.add(result);
      });
    }
  }

  void _editFaculty(Faculty faculty) async {
    final Faculty? result = await showDialog<Faculty>(
      context: context,
      builder: (context) => FacultyDialog(faculty: faculty),
    );
    if (result != null) {
      setState(() {
        final idx = facultyList.indexWhere((f) => f.id == result.id);
        if (idx != -1) facultyList[idx] = result;
      });
    }
  }

  void _deleteFaculty(Faculty faculty) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Faculty?'),
        content: Text('Remove "${faculty.name}" from the list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                setState(() => facultyList.removeWhere((c) => c.id == faculty.id));
                Navigator.pop(context, true);
              },
              child: const Text('Delete')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = facultyList.where((f) {
      final query = _searchText.toLowerCase();
      return f.name.toLowerCase().contains(query) ||
          f.department.toLowerCase().contains(query) ||
          f.cabinRoom.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Cabin Management'),
        actions: [
          IconButton(onPressed: _addFaculty, icon: const Icon(Icons.add), tooltip: 'Add Faculty'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // --- SEARCH BAR ---
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search faculty...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // --- FILTERED LIST ---
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                child: Text(
                  _searchText.isEmpty ? "No faculty added yet." : "No faculty found.",
                  style: const TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.separated(
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final faculty = filteredList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: faculty.profilePhoto.isNotEmpty
                          ? NetworkImage(faculty.profilePhoto)
                          : null,
                      child: faculty.profilePhoto.isEmpty
                          ? Text(faculty.name.isNotEmpty ? faculty.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(faculty.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${faculty.department} • ${faculty.cabinRoom}'),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: faculty.availability ? Colors.green : Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              faculty.availability ? "Available" : "Busy",
                              style: TextStyle(
                                fontSize: 12,
                                color: faculty.availability ? Colors.green : Colors.red,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editFaculty(faculty),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteFaculty(faculty),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Faculty Dialog
// ---------------------------------------------------------------------------
class FacultyDialog extends StatefulWidget {
  final Faculty? faculty;
  const FacultyDialog({Key? key, this.faculty}) : super(key: key);

  @override
  State<FacultyDialog> createState() => _FacultyDialogState();
}

class _FacultyDialogState extends State<FacultyDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _deptCtrl;
  late TextEditingController _cabinCtrl;
  late TextEditingController _photoCtrl;
  bool _availability = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.faculty?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.faculty?.email ?? '');
    _passCtrl = TextEditingController(text: widget.faculty?.password ?? '');
    _deptCtrl = TextEditingController(text: widget.faculty?.department ?? '');
    _cabinCtrl = TextEditingController(text: widget.faculty?.cabinRoom ?? '');
    _photoCtrl = TextEditingController(text: widget.faculty?.profilePhoto ?? '');
    _availability = widget.faculty?.availability ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _deptCtrl.dispose();
    _cabinCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.faculty == null ? 'Add Faculty' : 'Edit Faculty'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 8),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
          const SizedBox(height: 8),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
          const SizedBox(height: 8),
          TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business))),
          const SizedBox(height: 8),
          TextField(controller: _cabinCtrl, decoration: const InputDecoration(labelText: 'Cabin Room', prefixIcon: Icon(Icons.room))),
          const SizedBox(height: 8),
          TextField(controller: _photoCtrl, decoration: const InputDecoration(labelText: 'Profile Photo URL', prefixIcon: Icon(Icons.image))),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text("Available"),
            value: _availability,
            onChanged: (val) => setState(() => _availability = val),
            secondary: Icon(Icons.check_circle, color: _availability ? Colors.green : Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.isEmpty || _deptCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Department are required')));
              return;
            }
            final f = Faculty(
              id: widget.faculty?.id ?? '',
              name: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text.trim(),
              department: _deptCtrl.text.trim(),
              cabinRoom: _cabinCtrl.text.trim(),
              profilePhoto: _photoCtrl.text.trim(),
              availability: _availability,
            );
            Navigator.pop(context, f);
          },
          child: const Text('Save'),
        )
      ],
    );
  }
}