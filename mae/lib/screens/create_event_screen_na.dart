import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'registration_success_screen_na.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'payment_screen_na.dart';

class CreateEventScreenNA extends StatefulWidget {
  const CreateEventScreenNA({Key? key}) : super(key: key);

  @override
  State<CreateEventScreenNA> createState() => _CreateEventScreenNAState();
}

class _CreateEventScreenNAState extends State<CreateEventScreenNA> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String _status = 'PENDING';

  // Image picker related variables
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _webImageBytes;

  bool _isSubmitting = false;
  String? _submitError;

  // Function to pick image from gallery
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

  // Add this helper function inside your State class
  // Future<File?> _compressFile(File file) async {
  //   final filePath = file.absolute.path;
  //   final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
  //   final split = filePath.substring(0, lastIndex);
  //   final outPath = "${split}_out${filePath.substring(lastIndex)}";

  //   var result = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     outPath,
  //     quality: 70, // compress quality (0-100)
  //   );

  //   return result;
  // }

  Future<String?> _uploadImage() async {
    if (_imageFile == null && _webImageBytes == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref();

      // Helper to get the file extension from the file path
      String _getFileExtension(String path) {
        return path.contains('.')
            ? path.substring(path.lastIndexOf('.'))
            : '.jpg';
      }

      String fileExtension = '.jpg';
      if (!kIsWeb && _imageFile != null) {
        fileExtension = _getFileExtension(_imageFile!.path);
      }

      final fileName =
          'event_images/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final ref = storageRef.child(fileName);

      UploadTask uploadTask;

      if (kIsWeb && _webImageBytes != null) {
        // For web, upload raw bytes (compression is complex here)
        uploadTask = ref.putData(_webImageBytes!);
      } else if (_imageFile != null) {
        // For mobile, temporarily skip compression to isolate upload issues
        print("Uploading original image (compression skipped)...");
        uploadTask = ref.putFile(_imageFile!);
      } else {
        return null;
      }

      // Optional: Listen to upload progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Upload is ${(progress * 100).toStringAsFixed(2)}% complete.');
        },
        onError: (error) {
          print('Upload error: $error');
        },
      );

      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          throw Exception('Image upload timed out.');
        },
      );

      final url = await snapshot.ref.getDownloadURL();
      print("Upload successful! Download URL: $url");
      return url;
    } catch (e, stack) {
      print("Image upload failed: $e");
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
      setState(() {
        _submitError = 'Upload error: $e';
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

      // Save event to Firestore
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

      // Create Event object
      final event = Event(
        name: _eventNameController.text,
        date: _dateController.text,
        time: _timeController.text,
        location: _locationController.text,
        organizer: _organizerController.text,
        fee: double.tryParse(_feeController.text) ?? 0.0,
        status: 'PENDING',
        imageUrl: imageUrl ?? '',
        details: _detailsController.text,
      );

      setState(() {
        _isSubmitting = false;
      });

      // Navigate to PaymentScreen passing event data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PaymentScreenNA(
                event: event,
                onPaymentComplete: () {
                  // Optional: refresh or callback after payment done
                },
              ),
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
                    _buildTextField('Event Name', _eventNameController, true),
                    const SizedBox(height: 12),
                    _buildTextField('Location', _locationController, true),
                    const SizedBox(height: 12),
                    _buildDatePicker('Date', _dateController),
                    const SizedBox(height: 12),
                    _buildTimePicker('Time', _timeController),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Fee Charges',
                      _feeController,
                      true,
                      isNumber: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Organized by', _organizerController, true),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'External Website',
                      _websiteController,
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Details',
                      _detailsController,
                      true,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
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
                                      color: Colors.white,
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isRequired, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: '$label${isRequired ? '*' : ''}',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            validator:
                isRequired
                    ? (value) =>
                        value == null || value.isEmpty ? 'Required' : null
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
                controller.text =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                setState(() {});
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: label + '*',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
                controller.text = picked.format(context);
                setState(() {});
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '$label*',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
