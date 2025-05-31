import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import 'registration_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Event event;
  final VoidCallback onPaymentComplete;
  final String? initialName;
  final String? initialEmail;

  const PaymentScreen({
    Key? key,
    required this.event,
    required this.onPaymentComplete,
    this.initialName,
    this.initialEmail,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'Debit/Credit Card';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  String? _cardError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Register Details',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Applicant Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Applicant Name*',
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email*',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Register Fee',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'RM ${widget.event.fee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PAYMENT METHOD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<String>(
                    value: 'Ewallet',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  const Text('Ewallet'),
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Debit/Credit Card',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  const Text('Debit/Credit Card'),
                  const SizedBox(width: 4),
                  Container(width: 30, height: 10, color: Colors.grey.shade300),
                ],
              ),
              if (_selectedPaymentMethod == 'Debit/Credit Card')
                Column(
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Card Number*',
                        errorText: _cardError,
                      ),
                      maxLength: 16,
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      _cardError = null;
                      _nameError = null;
                    });
                    if (_nameController.text.trim().isEmpty) {
                      setState(() {
                        _nameError = 'Applicant name is required.';
                      });
                      return;
                    }
                    if (_selectedPaymentMethod == 'Debit/Credit Card') {
                      final card = _cardNumberController.text.trim();
                      if (card.length != 16 || int.tryParse(card) == null) {
                        setState(() {
                          _cardError = 'Card number must be exactly 16 digits.';
                        });
                        return;
                      }
                    }
                    await FirebaseFirestore.instance
                        .collection('registrations')
                        .add({
                          'applicantName': _nameController.text,
                          'email': _emailController.text,
                          'uid':
                              FirebaseFirestore.instance
                                  .collection('credentials')
                                  .doc(
                                    FirebaseFirestore.instance
                                        .collection('uid')
                                        .doc()
                                        .id,
                                  )
                                  .id,
                          'eventName': widget.event.name,
                          'eventId': widget.event.id,
                          'eventDetails': {
                            'name': widget.event.name,
                            'organizer': widget.event.organizer,
                            'date': widget.event.date,
                            'time': widget.event.time,
                            'location': widget.event.location,
                            'fee': widget.event.fee,
                            'status': widget.event.status,
                            'imageUrl': widget.event.imageUrl,
                            'details': widget.event.details,
                          },
                          'registeredAt': FieldValue.serverTimestamp(),
                        });
                    // Update event applicant and fee_collected
                    final eventDoc =
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(widget.event.id)
                            .get();
                    if (eventDoc.exists) {
                      final data = eventDoc.data() ?? {};
                      final currentApplicant =
                          (data['applicant'] is int) ? data['applicant'] : 0;
                      final currentFeeCollected =
                          (data['fee_collected'] is num)
                              ? data['fee_collected'].toDouble()
                              : 0.0;
                      await eventDoc.reference.update({
                        'applicant': currentApplicant + 1,
                        'fee_collected': currentFeeCollected + widget.event.fee,
                      });
                    }
                    widget.onPaymentComplete();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrationSuccessScreen(),
                      ),
                    );
                  },
                  child: const Text('Confirm Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
