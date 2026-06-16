import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/event_provider.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // <-- Your code
  final _picker = ImagePicker(); // <-- Your code
  static const String _imgbbApiKey = 'e65dda1999c0ee67415a324643ded9a6';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // <-- Your code
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;
    if (kIsWeb) {
      // Web: read bytes
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImage = null;
      });
    } else {
      // Mobile: use File
      setState(() {
        _selectedImage = File(picked.path);
        _selectedImageBytes = null;
      });
    }
  }

  // <-- Your code
  Future<String?> _uploadImage() async {
    Uint8List? imageBytes;
    if (kIsWeb) {
      imageBytes = _selectedImageBytes;
    } else {
      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
      }
    }
    if (imageBytes == null) return null;
    try {
      final base64Image = base64Encode(imageBytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a date')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final imageUrl = await _uploadImage(); // <-- Your code

    if (mounted) Navigator.pop(context);
    await ref
        .read(createEventControllerProvider.notifier)
        .createEvent(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          date: _selectedDate!,
          imageUrl: imageUrl, // <-- Your code
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createEventControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Event created!')));
          _formKey.currentState!.reset();
          _titleController.clear();
          _descController.clear();
          _locationController.clear();
          setState(() {
            _selectedDate = null;
            _selectedImage = null; // <-- Clear image too
            _selectedImageBytes = null;
          });
        },
        error: (err, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err.toString()))),
      );
    });

    final createState = ref.watch(createEventControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v!.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDate == null
                      ? 'Pick Date & Time'
                      : DateFormat(
                          'EEE, MMM d, y • h:mm a',
                        ).format(_selectedDate!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDate,
              ),

              // <-- Your image picker widget
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildImagePreview(),
                ),
              ),

              const SizedBox(height: 24),
              createState.isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                      onPressed: _submit,
                      child: const Text('Create Event'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
      );
    } else if (!kIsWeb && _selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('Add Event Image'),
        ],
      );
    }
  }
}
