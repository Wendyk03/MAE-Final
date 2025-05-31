import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/create_event_screen.dart';

class EventsTabNA extends StatelessWidget {
  const EventsTabNA({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.deepPurple.shade300),
            const SizedBox(height: 24),
            const Text(
              'Create New Event',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This section is for external organizers to propose and manage events.\n\nYou will not be able to register or join any events here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.deepPurple,
                foregroundColor:
                    Colors.white, // <-- set your desired text color here
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final double fee;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.fee,
  });

  factory Event.fromFirestore(Map<String, dynamic> data) {
    DateTime parsedDate;
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      parsedDate = DateTime.tryParse(data['date']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    return Event(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: parsedDate,
      time: TimeOfDay.fromDateTime(parsedDate),
      fee: double.tryParse(data['fee'].toString()) ?? 0.0,
    );
  }
}
