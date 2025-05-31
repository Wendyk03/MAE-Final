import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationTab extends StatelessWidget {
  const AdminNotificationTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<String> filter = ValueNotifier<String>('All');
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: filter,
                  builder: (context, value, _) {
                    return Row(
                      children: [
                        Checkbox(
                          value: value == 'Unread',
                          onChanged: (checked) {
                            filter.value = checked! ? 'Unread' : 'All';
                          },
                        ),
                        const Text('Show only unread notifications'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return const Center(child: Text('No notifications.'));
                }

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> notifications = [];

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? '';
                  final subtitle = data['subtitle'] ?? '';
                  final status = data['status'] ?? '';
                  final createdAt = data['createdAt'];
                  final createdDate =
                      createdAt != null
                          ? (createdAt is Timestamp
                              ? createdAt.toDate()
                              : DateTime.tryParse(createdAt.toString()))
                          : null;
                  final isRead = data['isRead'] == true;
                  String timeAgo = '';
                  if (createdDate != null) {
                    final diff = DateTime.now().difference(createdDate);
                    if (diff.inDays > 0) {
                      timeAgo =
                          '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
                    } else if (diff.inHours > 0) {
                      timeAgo =
                          '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
                    } else {
                      timeAgo = '${diff.inMinutes} min ago';
                    }
                  }

                  // Choose icon and color based on status
                  IconData icon = Icons.notifications;
                  Color color = Colors.blueGrey;
                  if (status == 'PENDING') {
                    icon = Icons.hourglass_empty;
                    color = Colors.orange;
                  } else if (status == 'UPDATE_REQUESTED') {
                    icon = Icons.edit;
                    color = Colors.blue;
                  } else if (status == 'UPDATED') {
                    icon = Icons.update;
                    color = Colors.cyan;
                  } else if (status == 'APPROVED') {
                    icon = Icons.check_circle;
                    color = Colors.green;
                  } else if (status == 'COMPLETED') {
                    icon = Icons.event_available;
                    color = Colors.purple;
                  }

                  notifications.add({
                    'title': title,
                    'subtitle': subtitle,
                    'icon': icon,
                    'color': color,
                    'time': timeAgo,
                    'isRead': isRead,
                    'docId': doc.id,
                  });
                }

                return ValueListenableBuilder<String>(
                  valueListenable: filter,
                  builder: (context, value, _) {
                    List<Map<String, dynamic>> filtered = notifications;
                    if (value == 'Unread') {
                      filtered =
                          notifications
                              .where((n) => n['isRead'] == false)
                              .toList();
                    } else if (value == 'Read') {
                      filtered =
                          notifications
                              .where((n) => n['isRead'] == true)
                              .toList();
                    }
                    if (filtered.isEmpty) {
                      return const Center(child: Text('No notifications.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = filtered[index];
                        return Card(
                          color:
                              notification['isRead']
                                  ? Colors.grey.shade200
                                  : Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              notification['icon'] as IconData,
                              color: notification['color'] as Color,
                              size: 32,
                            ),
                            title: Text(
                              notification['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(notification['subtitle'] as String),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notification['time'] as String,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Checkbox(
                                  value: notification['isRead'],
                                  onChanged: (val) async {
                                    await FirebaseFirestore.instance
                                        .collection('notification')
                                        .doc(notification['docId'])
                                        .update({'isRead': val});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
