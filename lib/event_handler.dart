import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

// --- Event Model ---
class Event {
  String id;
  String title;
  String description;
  DateTime date;
  String imageUrl;
  List<String> regulations;
  String registrationLink;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.regulations,
    required this.registrationLink,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      imageUrl: json['imageUrl'] ?? '',
      regulations: json['regulations'] != null
          ? List<String>.from(json['regulations'])
          : [],
      registrationLink: json['registrationLink'] ?? '',
    );
  }
}

// --- Page Widget ---
class EventHandlerPage extends StatefulWidget {
  const EventHandlerPage({super.key});

  @override
  State<EventHandlerPage> createState() => _EventHandlerPageState();
}

class _EventHandlerPageState extends State<EventHandlerPage> {
  List<Event> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final eventsData = await ApiService.getAllEvents();
      final events = eventsData.map((e) => Event.fromJson(e)).toList();

      // Sort by date (earliest first)
      events.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _events = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.trim().isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL format')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar here because AdminHomePage already provides one.
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : _events.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView.builder(
          padding: const EdgeInsets.only(
              left: 16, right: 16, top: 16, bottom: 80),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(_events[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditEventDialog(context),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load events',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No Events Yet',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text('Tap the button below to add your first event',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade300,
                            Colors.deepPurple.shade600
                          ],
                        ),
                      ),
                      child: const Center(
                          child:
                          Icon(Icons.event, size: 60, color: Colors.white)),
                    ),
                  ),
                ),
                // Floating Action Buttons on Card
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _actionIcon(
                        Icons.edit,
                        Colors.blue,
                            () => _showAddEditEventDialog(context, event: event),
                      ),
                      const SizedBox(width: 8),
                      _actionIcon(
                        Icons.delete,
                        Colors.red,
                            () => _showDeleteConfirmation(context, event),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(event.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Link Section
                if (event.registrationLink.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchURL(event.registrationLink),
                    child: Row(
                      children: const [
                        Icon(Icons.link, size: 18, color: Colors.blue),
                        SizedBox(width: 6),
                        Text('Registration Link',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.rule, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    Text(
                      '${event.regulations.length} Regulations',
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }

  // --- Dialogs ---

  void _showAddEditEventDialog(BuildContext context, {Event? event}) {
    final isEdit = event != null;
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final descCtrl = TextEditingController(text: event?.description ?? '');
    final imgCtrl = TextEditingController(text: event?.imageUrl ?? '');
    final linkCtrl = TextEditingController(text: event?.registrationLink ?? '');

    DateTime selectedDate =
        event?.date ?? DateTime.now().add(const Duration(days: 1));
    List<String> regulations = List.from(event?.regulations ?? ['']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 650),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dialog Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(isEdit ? Icons.edit : Icons.add_circle,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Event' : 'Add New Event',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Dialog Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: titleCtrl,
                              decoration: InputDecoration(
                                labelText: 'Event Title',
                                prefixIcon: const Icon(Icons.title),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: descCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: linkCtrl,
                              decoration: InputDecoration(
                                labelText: 'Registration Link (Optional)',
                                hintText: 'https://forms.google.com/...',
                                prefixIcon: const Icon(Icons.link),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Date Picker
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setDialogState(() => selectedDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        color: Colors.deepPurple),
                                    const SizedBox(width: 12),
                                    Text(
                                        'Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                                        style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: imgCtrl,
                              decoration: InputDecoration(
                                labelText: 'Image URL',
                                prefixIcon: const Icon(Icons.image),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Regulations List
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Regulations',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() => regulations.add(''));
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Rule'),
                                ),
                              ],
                            ),
                            ...regulations.asMap().entries.map((entry) {
                              int idx = entry.key;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          labelText: 'Rule ${idx + 1}',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(12)),
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                        onChanged: (val) =>
                                        regulations[idx] = val,
                                        controller: TextEditingController(
                                            text: regulations[idx])
                                          ..selection = TextSelection.collapsed(
                                              offset:
                                              regulations[idx].length),
                                      ),
                                    ),
                                    if (regulations.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () {
                                          setDialogState(
                                                  () => regulations.removeAt(idx));
                                        },
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    // Dialog Actions
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (titleCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                          Text('Please enter event title'),
                                          backgroundColor: Colors.orange));
                                  return;
                                }
                                try {
                                  final cleanRegs = regulations
                                      .where((r) => r.trim().isNotEmpty)
                                      .toList();
                                  final defaultImg =
                                      'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800';
                                  final finalImg = imgCtrl.text.isEmpty
                                      ? defaultImg
                                      : imgCtrl.text;

                                  if (isEdit) {
                                    await ApiService.updateEvent(
                                      eventId: event.id,
                                      title: titleCtrl.text,
                                      description: descCtrl.text,
                                      date: selectedDate,
                                      imageUrl: finalImg,
                                      regulations: cleanRegs,
                                      registrationLink: linkCtrl.text.trim(),
                                    );
                                  } else {
                                    await ApiService.createEvent(
                                      title: titleCtrl.text,
                                      description: descCtrl.text,
                                      date: selectedDate,
                                      imageUrl: finalImg,
                                      regulations: cleanRegs,
                                      registrationLink: linkCtrl.text.trim(),
                                    );
                                  }
                                  await _loadEvents();
                                  if (context.mounted) Navigator.pop(context);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Success!'),
                                            backgroundColor: Colors.green));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(isEdit ? 'Update' : 'Add Event',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text('Delete Event?')
        ]),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService.deleteEvent(event.id);
                await _loadEvents();
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Deleted'), backgroundColor: Colors.red));
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}