// lib/events_page.dart
import 'package:flutter/material.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amrita Vishwa Vidyapeetham'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Event Image
            GestureDetector(
              onTap: () {
                _showEventDetailsPopup(context);
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(), // keep decoration separate to allow errorBuilder
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Use AssetImage but guard with errorBuilder so missing assets don't crash UI
                    Image.asset(
                      'assets/event_image.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.black54,
                        child: const Text(
                          'Explore the Deep Blue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Sliding Upcoming Events
            SizedBox(
              height: 150, // Adjust height as needed
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5, // Example: 5 upcoming events
                itemBuilder: (context, index) {
                  return _buildUpcomingEventCard(context, index);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      // NOTE: do NOT include another bottom navigation here. StudentHomePage provides the app's nav.
    );
  }

  Widget _buildUpcomingEventCard(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        _showEventDetailsPopup(context, eventTitle: 'Upcoming Event ${index + 1}');
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image with errorBuilder to avoid runtime image NotFound errors
              SizedBox(
                height: 80,
                width: double.infinity,
                child: Image.asset(
                  'assets/upcoming_event_${index + 1}.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.event, size: 36)),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Upcoming Event ',
                  key: Key('upcomingTitlePlaceholder'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Date: Nov ${10 + index}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetailsPopup(BuildContext context, {String eventTitle = 'Explore the Deep Blue'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75, // 75% of screen height
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventTitle,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join us for an exhilarating journey into the mesmerizing underwater world! Discover diverse marine life, explore vibrant coral reefs, and experience the tranquility of the ocean\'s depths. This event is perfect for both seasoned divers and beginners looking to try something new. Our certified instructors will ensure a safe and unforgettable adventure.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Rules & Regulations:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRuleItem('Participants must be 18 years or older.'),
                        _buildRuleItem('All participants must sign a liability waiver.'),
                        _buildRuleItem('Basic swimming ability is required.'),
                        _buildRuleItem('Follow all instructions from the diving instructors.'),
                        _buildRuleItem('Respect marine life and the environment.'),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle registration
                              Navigator.pop(context); // Close the popup
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Registered for $eventTitle!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple, // Button color
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Register Now',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
