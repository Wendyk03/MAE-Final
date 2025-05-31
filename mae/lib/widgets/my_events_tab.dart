import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../screens/update_event_screen.dart';
import 'my_event_card.dart';

class MyEventsTab extends StatelessWidget {
  const MyEventsTab({Key? key}) : super(key: key);

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
        final pendingEvents =
            events.where((e) => e.status == 'PENDING').toList();
        final approvedEvents =
            events.where((e) => e.status == 'APPROVED').toList();
        // Remove unused rejectedEvents variable, as rejected events are now fetched from the 'rejected' collection below
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PENDING EVENT',
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
                  itemCount: pendingEvents.length,
                  itemBuilder: (context, index) {
                    return MyEventCard(
                      event: pendingEvents[index],
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => UpdateEventScreen(
                                  event: pendingEvents[index],
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'YOUR UPCOMING EVENTS',
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
                  itemCount: approvedEvents.length,
                  itemBuilder: (context, index) {
                    return MyEventCard(
                      event: approvedEvents[index],
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => UpdateEventScreen(
                                  event: approvedEvents[index],
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'REJECTED EVENTS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('rejected')
                          .orderBy('rejectedAt', descending: true)
                          .snapshots(),
                  builder: (context, rejectedSnapshot) {
                    if (rejectedSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!rejectedSnapshot.hasData ||
                        rejectedSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No rejected events.'));
                    }
                    final rejectedEvents =
                        rejectedSnapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Event(
                            name: data['name'] ?? '',
                            organizer: data['organizer'] ?? '',
                            date: data['date'] ?? '',
                            time: data['time'] ?? '',
                            location: data['location'] ?? '',
                            fee: double.tryParse(data['fee'].toString()) ?? 0.0,
                            status: data['status'] ?? 'REJECTED',
                            rejectionReason: data['rejectionReason'],
                          );
                        }).toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rejectedEvents.length,
                      itemBuilder: (context, index) {
                        return MyEventCard(
                          event: rejectedEvents[index],
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => UpdateEventScreen(
                                      event: rejectedEvents[index],
                                    ),
                              ),
                            );
                          },
                        );
                      },
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
