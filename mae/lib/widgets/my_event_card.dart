import 'package:flutter/material.dart';
import '../models/event.dart';

class MyEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEdit;
  const MyEventCard({
    Key? key,
    required this.event,
    required this.onEdit, // <-- add required here
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> dateParts = event.date.split(' ');
    String dateMain = dateParts.isNotEmpty ? dateParts[0] : '';
    String dateSub = dateParts.length > 1 ? dateParts[1] : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    dateMain,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    dateSub,
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.info_outline),
              label: const Text('Details'),
            ),
          ],
        ),
      ),
    );
  }
}
