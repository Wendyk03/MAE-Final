import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event.dart';

class UpdateEventScreen extends StatefulWidget {
  final Event event;
  const UpdateEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<UpdateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<UpdateEventScreen> {
  late Event event;
  bool _eventDetailsExpanded = true;
  bool _eventDetailsExpanded2 = true;
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _webImageBytes;

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    _eventNameController.text = event.name;
    _locationController.text = event.location;
    _dateController.text = event.date;
    _timeController.text = event.time;
    _feeController.text = event.fee.toString();
    _organizerController.text = event.organizer;
    _detailsController.text = event.details ?? '';
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null && _webImageBytes == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileName =
          'event_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storageRef.child(fileName);
      UploadTask uploadTask;
      if (kIsWeb && _webImageBytes != null) {
        uploadTask = ref.putData(_webImageBytes!);
      } else if (_imageFile != null) {
        uploadTask = ref.putFile(_imageFile!);
      } else {
        return null;
      }
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Image upload timed out.');
        },
      );
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Image upload error: $e');
      setState(() {
        _submitError = 'Image upload failed: $e';
      });
      return null;
    }
  }

  // Remove unused _submitEvent method

  // Add this function to handle update for rejected events
  Future<void> _updateRejectedEvent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _submitError = 'Please fill all required fields.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      String? imageUrl;
      if (_imageFile != null || _webImageBytes != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null || imageUrl.isEmpty) {
          setState(() {
            _isSubmitting = false;
            _submitError = 'Image upload failed. Event not updated.';
          });
          return;
        }
      } else {
        imageUrl = event.imageUrl;
      }
      // Add event back to 'events' collection (exclude rejection reason)
      await FirebaseFirestore.instance.collection('events').add({
        'name': _eventNameController.text,
        'location': _locationController.text,
        'date': _dateController.text,
        'time': _timeController.text,
        'fee': _feeController.text,
        'organizer': _organizerController.text,
        'website': _websiteController.text,
        'details': _detailsController.text,
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });
      // Delete from 'rejected' collection
      final rejectedQuery =
          await FirebaseFirestore.instance
              .collection('rejected')
              .where('name', isEqualTo: event.name)
              .where('organizer', isEqualTo: event.organizer)
              .where('date', isEqualTo: event.date)
              .limit(1)
              .get();
      for (var doc in rejectedQuery.docs) {
        await doc.reference.delete();
      }
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError = 'Failed to update: \n' + e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Event Register',
          style: TextStyle(color: Colors.black),
        ),
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
                  kIsWeb
                      ? (_webImageBytes != null
                          ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                          : (event.imageUrl.isNotEmpty
                              ? Image.network(event.imageUrl, fit: BoxFit.cover)
                              : _buildUploadPlaceholder(showButton: false)))
                      : (_imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : (event.imageUrl.isNotEmpty
                              ? Image.network(event.imageUrl, fit: BoxFit.cover)
                              : _buildUploadPlaceholder(showButton: false))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _pickImage,
                  child: const Text('Upload Event Poster'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _eventDetailsExpanded = !_eventDetailsExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blueGrey.shade200
                                    : Colors.blue.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'EVENT INFORMATIONS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _eventDetailsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_eventDetailsExpanded)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Event Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _eventNameController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Event Name*',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _locationController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Location*',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        _dateController.text =
                                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                        setState(() {});
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: _dateController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Date*',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        validator:
                                            (value) =>
                                                value == null || value.isEmpty
                                                    ? 'Required'
                                                    : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();
                                      TimeOfDay? picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) {
                                        _timeController.text = picked.format(
                                          context,
                                        );
                                        setState(() {});
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: _timeController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Time*',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        validator:
                                            (value) =>
                                                value == null || value.isEmpty
                                                    ? 'Required'
                                                    : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Fee Charges',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _feeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Fee Charges*',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Organized by',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _organizerController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Organizer*',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'External Website',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _websiteController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'External Website',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _detailsController,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Details*',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            // Show rejection reason if status is REJECTED
                            if (event.status == 'REJECTED' &&
                                event.rejectionReason != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Rejection Reason:',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.rejectionReason ?? '',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (event.status == 'APPROVED') ...[
                      SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _eventDetailsExpanded2 = !_eventDetailsExpanded2;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blueGrey.shade200
                                      : Colors.blue.shade300,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade100,
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'EVENT DETAILS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _eventDetailsExpanded2
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_eventDetailsExpanded2)
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blueGrey.shade200
                                      : Colors.blue.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    'Number of Applicants:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('0'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  Text(
                                    'Total Fee Collected:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('RM 0.00'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(fontSize: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text('Download Applicants List'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () async {
                                    // Show confirmation dialog
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('Confirm Update'),
                                            content: const Text(
                                              'Are you sure you want to update this event?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(true),
                                                child: const Text('Update'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirmed == true) {
                                      await _updateRejectedEvent();
                                    }
                                  },
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Update',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    if (_submitError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _submitError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder({bool showButton = true}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image, color: Colors.white, size: 40),
        const SizedBox(height: 8),
        if (showButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Upload Event Poster',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _pickImage,
                child: const Text('Upload'),
              ),
            ],
          ),
      ],
    );
  }
}
