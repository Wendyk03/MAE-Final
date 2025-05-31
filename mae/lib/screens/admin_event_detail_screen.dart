import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../utils/date_utils.dart';
import './admin_home_screen.dart';
import './request_update_screen.dart';

class AdminEventDetailScreen extends StatefulWidget {
  final Event event;
  final Function(Event) onRegister;

  const AdminEventDetailScreen({
    Key? key,
    required this.event,
    required this.onRegister,
  }) : super(key: key);

  @override
  State<AdminEventDetailScreen> createState() => _AdminEventDetailScreenState();
}

class _AdminEventDetailScreenState extends State<AdminEventDetailScreen> {
  int applicantCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplicantCount();
  }

  Future<void> _fetchApplicantCount() async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('events')
              .where('name', isEqualTo: widget.event.name)
              .where('date', isEqualTo: widget.event.date)
              .where('organizer', isEqualTo: widget.event.organizer)
              .limit(1)
              .get();
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        setState(() {
          applicantCount = (data['applicant'] ?? 0) as int;
          isLoading = false;
        });
      } else {
        setState(() {
          applicantCount = 0;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        applicantCount = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
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
                                : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Admin version: Conditional action buttons based on event status
                  if (event.status == 'PENDING' ||
                      event.status == 'ACTION NEEDED') ...[
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Confirm Approval'),
                                        content: const Text(
                                          'Are you sure you want to approve this event?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: const Text('Confirm'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  // Update event status in Firestore
                                  await FirebaseFirestore.instance
                                      .collection('events')
                                      .where('name', isEqualTo: event.name)
                                      .where('date', isEqualTo: event.date)
                                      .where(
                                        'organizer',
                                        isEqualTo: event.organizer,
                                      )
                                      .get()
                                      .then((snapshot) async {
                                        for (var doc in snapshot.docs) {
                                          await doc.reference.update({
                                            'status': 'APPROVED',
                                          });
                                        }
                                      });
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AdminHomeScreen(
                                            toggleTheme: () {},
                                            isDarkMode: false,
                                          ),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                minimumSize: const Size(120, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Approve',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final TextEditingController reasonController =
                                    TextEditingController();
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Confirm Rejection'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Are you sure you want to reject this event?',
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: reasonController,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Reason for rejection',
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: const Text('Confirm'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  final reason = reasonController.text.trim();
                                  // Find and delete the event, then add to 'rejected' collection with reason
                                  final query =
                                      await FirebaseFirestore.instance
                                          .collection('events')
                                          .where('name', isEqualTo: event.name)
                                          .where('date', isEqualTo: event.date)
                                          .where(
                                            'organizer',
                                            isEqualTo: event.organizer,
                                          )
                                          .get();
                                  for (var doc in query.docs) {
                                    final eventData = doc.data();
                                    await doc.reference.delete();
                                    await FirebaseFirestore.instance
                                        .collection('rejected')
                                        .add({
                                          ...eventData,
                                          'rejectionReason': reason,
                                          'status': 'REJECTED',
                                          'rejectedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                  }
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AdminHomeScreen(
                                            toggleTheme: () {},
                                            isDarkMode: false,
                                          ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                minimumSize: const Size(120, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => RequestUpdateScreen(
                                          eventId:
                                              event.name +
                                              '_' +
                                              event.date +
                                              '_' +
                                              event
                                                  .organizer, // fallback composite id
                                          eventTitle: event.name,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade500,
                                minimumSize: const Size(180, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Request Update',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else if (event.status == 'APPROVED') ...[
                    if (isLoading) ...[
                      const Center(child: CircularProgressIndicator()),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (applicantCount == 0) ...[
                            ElevatedButton(
                              onPressed: () async {
                                final TextEditingController reasonController =
                                    TextEditingController();
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Terminate Event'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Are you sure you want to terminate this event?',
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: reasonController,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Reason for termination',
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: const Text('Confirm'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  final reason = reasonController.text.trim();
                                  // Find and update the event status to 'TERMINATED' with reason and timestamp
                                  final query =
                                      await FirebaseFirestore.instance
                                          .collection('events')
                                          .where('name', isEqualTo: event.name)
                                          .where('date', isEqualTo: event.date)
                                          .where(
                                            'organizer',
                                            isEqualTo: event.organizer,
                                          )
                                          .get();
                                  for (var doc in query.docs) {
                                    await FirebaseFirestore.instance
                                        .collection('terminate')
                                        .add({
                                          ...doc.data(),
                                          'status': 'TERMINATED',
                                          'terminationReason': reason,
                                          'terminatedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                    await doc.reference.delete();
                                  }
                                  if (mounted) {
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AdminHomeScreen(
                                              toggleTheme: () {},
                                              isDarkMode: false,
                                            ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                minimumSize: const Size(120, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Terminate',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => RequestUpdateScreen(
                                        eventId:
                                            event.name +
                                            '_' +
                                            event.date +
                                            '_' +
                                            event
                                                .organizer, // fallback composite id
                                        eventTitle: event.name,
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade500,
                              minimumSize: const Size(120, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Request Update',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  // If status is 'END', show no buttons
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
