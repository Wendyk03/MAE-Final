import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisteredEventsTab extends StatelessWidget {
  const RegisteredEventsTab({Key? key}) : super(key: key);

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
    final today = DateTime(2025, 5, 13);
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('registrations')
              .orderBy('registeredAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No registered events yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Apply for events to see them here',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final registrations =
            snapshot.data!.docs.where((doc) {
              final reg = doc.data() as Map<String, dynamic>;
              return reg['uid'] == user?.uid;
            }).toList();
        final List<QueryDocumentSnapshot> upcoming = [];
        final List<QueryDocumentSnapshot> current = [];
        final List<QueryDocumentSnapshot> past = [];
        for (final doc in registrations) {
          final event =
              (doc.data() as Map<String, dynamic>)['eventDetails'] ?? {};
          final dateStr = event['date'] ?? '';
          final eventDate = _parseDate(dateStr);
          if (eventDate == null) continue;
          final eventDay = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
          );
          if (eventDay.isAfter(today)) {
            upcoming.add(doc);
          } else if (eventDay.isBefore(today)) {
            past.add(doc);
          } else {
            current.add(doc);
          }
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (current.isNotEmpty) ...[
              const Text(
                'Current',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...current.map((doc) => _eventCard(doc)),
              const SizedBox(height: 24),
            ],
            if (upcoming.isNotEmpty) ...[
              const Text(
                'Upcoming',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...upcoming.map((doc) => _eventCard(doc)),
              const SizedBox(height: 24),
            ],
            if (past.isNotEmpty) ...[
              const Text(
                'Past',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...past.map((doc) => _eventCard(doc)),
            ],
          ],
        );
      },
    );
  }

  Widget _eventCard(QueryDocumentSnapshot doc) {
    final reg = doc.data() as Map<String, dynamic>;
    final event = reg['eventDetails'] ?? {};
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'By: ${event['organizer'] ?? ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${event['date'] ?? ''}  Time: ${event['time'] ?? ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Location: ${event['location'] ?? ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Fee: RM ${event['fee']?.toStringAsFixed(0) ?? '0'}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Registered by: ${reg['applicantName'] ?? ''}',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
