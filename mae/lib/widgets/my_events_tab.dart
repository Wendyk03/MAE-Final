import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = FirebaseAuth.instance.currentUser;
        final events =
            snapshot.data!.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Only include events where uid matches current user
                  if (data['uid'] == user?.uid) {
                    return Event(
                      id: data['id'], // Pass the Firestore 'id' field to the Event model
                      name: data['name'] ?? '',
                      organizer: data['organizer'] ?? '',
                      date: data['date'] ?? '',
                      time: data['time'] ?? '',
                      location: data['location'] ?? '',
                      fee: double.tryParse(data['fee'].toString()) ?? 0.0,
                      status: data['status'] ?? '',
                      imageUrl: data['imageUrl'] ?? '',
                      details: data['details'],
                      rejectionReason: data['rejectionReason'],
                    );
                  }
                  return null;
                })
                .whereType<Event>()
                .toList();
        final pendingEvents =
            events
                .where(
                  (e) => e.status == 'PENDING' || e.status == 'ACTION NEEDED',
                )
                .toList();
        final approvedEvents =
            events.where((e) => e.status == 'APPROVED').toList();
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
                pendingEvents.isEmpty
                    ? const Center(child: Text('No pending events.'))
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingEvents.length,
                      itemBuilder: (context, index) {
                        return MyEventCard(
                          event: pendingEvents[index],
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => UpdateEventScreen(
                                      event: pendingEvents[index],
                                    ),
                              ),
                            );
                            (context as Element).markNeedsBuild();
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
                approvedEvents.isEmpty
                    ? const Center(child: Text('No upcoming events.'))
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: approvedEvents.length,
                      itemBuilder: (context, index) {
                        return MyEventCard(
                          event: approvedEvents[index],
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => UpdateEventScreen(
                                      event: approvedEvents[index],
                                    ),
                              ),
                            );
                            (context as Element).markNeedsBuild();
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
                        rejectedSnapshot.data!.docs
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['uid'] == user?.uid) {
                                return Event(
                                  id: data['id'], // Pass the Firestore 'id' field to the Event model
                                  name: data['name'] ?? '',
                                  organizer: data['organizer'] ?? '',
                                  date: data['date'] ?? '',
                                  time: data['time'] ?? '',
                                  location: data['location'] ?? '',
                                  fee:
                                      double.tryParse(data['fee'].toString()) ??
                                      0.0,
                                  status: data['status'] ?? 'REJECTED',
                                  rejectionReason: data['rejectionReason'],
                                  imageUrl: data['imageUrl'] ?? '',
                                  details: data['details'],
                                );
                              }
                              return null;
                            })
                            .whereType<Event>()
                            .toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rejectedEvents.length,
                      itemBuilder: (context, index) {
                        return MyEventCard(
                          event: rejectedEvents[index],
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => UpdateEventScreen(
                                      event: rejectedEvents[index],
                                    ),
                              ),
                            );
                            (context as Element).markNeedsBuild();
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'TERMINATED EVENTS',
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
                          .collection('terminate')
                          .orderBy('terminatedAt', descending: true)
                          .snapshots(),
                  builder: (context, terminatedSnapshot) {
                    if (terminatedSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!terminatedSnapshot.hasData ||
                        terminatedSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No terminated events.'));
                    }
                    final terminatedEvents =
                        terminatedSnapshot.data!.docs
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['uid'] == user?.uid) {
                                return Event(
                                  id: data['id'], // Pass the Firestore 'id' field to the Event model
                                  name: data['name'] ?? '',
                                  organizer: data['organizer'] ?? '',
                                  date: data['date'] ?? '',
                                  time: data['time'] ?? '',
                                  location: data['location'] ?? '',
                                  fee:
                                      double.tryParse(data['fee'].toString()) ??
                                      0.0,
                                  status: data['status'] ?? 'TERMINATED',
                                  rejectionReason: data['terminateReason'],
                                  imageUrl: data['imageUrl'] ?? '',
                                  details: data['details'],
                                );
                              }
                              return null;
                            })
                            .whereType<Event>()
                            .toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: terminatedEvents.length,
                      itemBuilder: (context, index) {
                        return MyEventCard(
                          event: terminatedEvents[index],
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => UpdateEventScreen(
                                      event: terminatedEvents[index],
                                    ),
                              ),
                            );
                            (context as Element).markNeedsBuild();
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
