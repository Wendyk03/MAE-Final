import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'registration_success_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
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

  Future<void> _submitEvent() async {
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
        print('DEBUG: Uploaded imageUrl: $imageUrl');
        if (imageUrl == null || imageUrl.isEmpty) {
          setState(() {
            _isSubmitting = false;
            _submitError = 'Image upload failed. Event not submitted.';
          });
          return;
        }
      } else {
        imageUrl = '';
      }
      // Add event to Firestore and get the generated document ID
      final docRef = await FirebaseFirestore.instance.collection('events').add({
        'name': _eventNameController.text,
        'location': _locationController.text,
        'date': _dateController.text,
        'time': _timeController.text,
        'fee': _feeController.text,
        'organizer': _organizerController.text,
        'website': _websiteController.text,
        'details': _detailsController.text,
        'status': 'PENDING',
        'applicant': 0,
        'fee_collected': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'id': '', // placeholder, will update below
      });
      // Update the event with its unique id
      await docRef.update({'id': docRef.id});
      // Add notification to 'notification' collection
      await FirebaseFirestore.instance.collection('notification').add({
        'title': 'New Event Pending Approval',
        'subtitle':
            'Event "${_eventNameController.text}" requires admin approval.',
        'eventName': _eventNameController.text,
        'status': 'PENDING',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isSubmitting = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegistrationSuccessScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError = 'Failed to submit: \n' + e.toString();
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
                          : _buildUploadPlaceholder())
                      : (_imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : _buildUploadPlaceholder()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EVENT DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Text(
                            'Event Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                                _timeController.text = picked.format(context);
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                          onPressed: _isSubmitting ? null : _submitEvent,
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Submit'),
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

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image, color: Colors.white, size: 40),
        const SizedBox(height: 8),
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
