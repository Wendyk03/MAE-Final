import 'package:flutter/material.dart';
import '../models/event.dart';
import 'payment_screen.dart';
import '../utils/date_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  final Function(Event) onRegister;

  const EventDetailScreen({
    Key? key,
    required this.event,
    required this.onRegister,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> dateParts = event.date.split(' ');
    String dateMain = dateParts.isNotEmpty ? dateParts[0] : '';
    String dateSub = dateParts.length > 1 ? dateParts[1] : '';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(event.name, style: const TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.blue.shade400,
              child:
                  event.imageUrl.isNotEmpty
                      ? Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Failed to load image: $error');
                          return Container(
                            height: 200,
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
                      : const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 40),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dateMain,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              dateSub,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
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
                            Text(
                              'with ${event.organizer}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formatEventDate(event.date) +
                        (event.time.isNotEmpty ? ' at ${event.time}' : ''),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (event.location.isNotEmpty) ...[
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      event.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      const Text(
                        'Register Fee',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RM ${event.fee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if ((event.details ?? '').isNotEmpty) ...[
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      event.details ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (event.status.isNotEmpty) ...[
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      event.status,
                      style: TextStyle(
                        color:
                            event.status == 'APPROVED'
                                ? Colors.green
                                : Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade500,
                        minimumSize: const Size(200, 50),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed:
                          event.isRegistered
                              ? null
                              : () async {
                                  final user = await FirebaseAuth.instance.currentUser;
                                  if (user == null) return;
                                  // Check if already registered
                                  final regQuery = await FirebaseFirestore.instance
                                      .collection('registrations')
                                      .where('uid', isEqualTo: user.uid)
                                      .where('eventId', isEqualTo: event.id)
                                      .limit(1)
                                      .get();
                                  if (regQuery.docs.isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Already Applied'),
                                        content: const Text('You have already applied for this event.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  // --- If not registered, proceed ---
                                  String? email;
                                  String? applicantName;
                                  final credDoc = await FirebaseFirestore.instance
                                      .collection('credentials')
                                      .doc(user.uid)
                                      .get();
                                  final credData = credDoc.data();
                                  email = credData?['email'] ?? user.email;
                                  final firstName = credData?['firstName'] ?? '';
                                  final lastName = credData?['lastName'] ?? '';
                                  applicantName = (firstName + ' ' + lastName).trim();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        event: event,
                                        onPaymentComplete: () {
                                          onRegister(event);
                                        },
                                        initialName: applicantName,
                                        initialEmail: email,
                                      ),
                                    ),
                                  );
                                },
                      child: Text(
                        event.isRegistered
                            ? 'Already Registered'
                            : 'Apply Now!',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
