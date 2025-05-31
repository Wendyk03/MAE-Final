import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'my_event_card.dart';

class AdminNotificationTab extends StatelessWidget {
  const AdminNotificationTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('notification')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No notifications found.'));
        }
        final notifications =
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
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOTIFICATIONS',
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
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return MyEventCard(
                      event: notifications[index],
                      onEdit: () {},
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
