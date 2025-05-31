import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'admin_events_finished_card.dart';

class AdminEventsFinishedTab extends StatelessWidget {
  const AdminEventsFinishedTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('events')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events found.'));
        }
        final events =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Event(
                name: data['name'] ?? '',
                organizer: data['organizer'] ?? '',
                date: data['date'] ?? '',
                time: data['time'] ?? '',
                location: data['location'] ?? '',
                fee: double.tryParse(data['fee'].toString()) ?? 0.0,
                status: data['status'] ?? '',
              );
            }).toList();
        final completedEvents = events.where((e) => e.status == 'END').toList();
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'EVENTS COMPLETED',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedEvents.length,
                  itemBuilder: (context, index) {
                    return AdminEventsFinishedCard(
                      event: completedEvents[index],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
