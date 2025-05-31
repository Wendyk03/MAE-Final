import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestUpdateScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const RequestUpdateScreen({
    Key? key,
    required this.eventId,
    required this.eventTitle,
  }) : super(key: key);

  @override
  State<RequestUpdateScreen> createState() => _RequestUpdateScreenState();
}

class _RequestUpdateScreenState extends State<RequestUpdateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitInstruction() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('instructions').add({
        'eventId': widget.eventId,
        'eventTitle': widget.eventTitle,
        'title': title,
        'description': desc,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Update event status to 'ACTION NEEDED' in events collection using eventId
      final eventDoc = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId);
      await eventDoc.update({'status': 'ACTION NEEDED'});
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Instruction submitted successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit instruction.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Update')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event: ${widget.eventTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Instruction Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Instruction Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitInstruction,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Submit Instruction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
