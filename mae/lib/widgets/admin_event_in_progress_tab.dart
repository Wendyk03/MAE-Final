import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../screens/admin_event_detail_screen.dart';
import '../utils/date_utils.dart';

class AdminEventInProgressTab extends StatelessWidget {
  const AdminEventInProgressTab({Key? key}) : super(key: key);

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime(2025, 5, 18);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Events In Progress',
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
                    snapshot.data!.docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
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
                        })
                        .where((event) {
                          if (event.status != 'APPROVED') return false;
                          final eventDate = _parseDate(event.date);
                          if (eventDate == null) return false;
                          final eventDay = DateTime(
                            eventDate.year,
                            eventDate.month,
                            eventDate.day,
                          );
                          return eventDay.compareTo(today) >= 0;
                        })
                        .toList();

                if (events.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No in progress events found.'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AdminEventDetailScreen(
                                  event: event,
                                  onRegister: (_) {},
                                ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child:
                                  event.imageUrl.isNotEmpty
                                      ? Image.network(
                                        event.imageUrl,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          print('Failed to load image: $error');
                                          return Container(
                                            height: 160,
                                            width: double.infinity,
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.error,
                                              size: 60,
                                              color: Colors.red,
                                            ),
                                          );
                                        },
                                      )
                                      : Container(
                                        height: 160,
                                        width: double.infinity,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.image,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatEventDate(event.date),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (event.details != null)
                                    Text(
                                      event.details!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
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
            ),
          ],
        ),
      ),
    );
  }
}
