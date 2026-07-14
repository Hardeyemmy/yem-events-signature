import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../events/domains/models/events.dart';
import '../providers/event_provider.dart';

class EditEventPage extends ConsumerStatefulWidget {
  const EditEventPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends ConsumerState<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;

  // Existing remote image from Firestore
  String? _existingImageUrl;

  // Newly picked image (mobile)
  File? _newImageFile;

  // Newly picked image (web)
  Uint8List? _newImageBytes;

  // Tracks if user explicitly removed the image
  bool _imageRemoved = false;

  bool _initialized = false;

  final _picker = ImagePicker();
  final String? _imgbbApiKey = dotenv.env['IMGBB_API_KEY'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeFields(Event event) {
    if (_initialized) return;
    _titleController.text = event.title;
    _descController.text = event.description;
    _locationController.text = event.location;
    _selectedDate = event.date;
    _existingImageUrl = event.imageUrl;
    _initialized = true;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newImageBytes = bytes;
        _newImageFile = null;
        _imageRemoved = false;
      });
    } else {
      setState(() {
        _newImageFile = File(picked.path);
        _newImageBytes = null;
        _imageRemoved = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _newImageFile = null;
      _newImageBytes = null;
      _imageRemoved = true;
    });
  }

  /// Same upload logic as CreateEventPage — ImgBB via base64
  Future<String?> _uploadImage() async {
    Uint8List? imageBytes;

    if (kIsWeb) {
      imageBytes = _newImageBytes;
    } else {
      if (_newImageFile != null) {
        imageBytes = await _newImageFile!.readAsBytes();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a date')));
      return;
    }

    String? finalImageUrl = _existingImageUrl;

    // User picked a new image — upload it
    final hasNewImage = _newImageFile != null || _newImageBytes != null;
    if (hasNewImage) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      finalImageUrl = await _uploadImage();
      if (mounted) Navigator.pop(context); // dismiss upload dialog
    }

    // User removed the image — set to null
    if (_imageRemoved) finalImageUrl = null;

    await ref
        .read(editEventControllerProvider(widget.eventId).notifier)
        .updateEvent(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          date: _selectedDate!,
          imageUrl: finalImageUrl,
        );

    final state = ref.read(editEventControllerProvider(widget.eventId));
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event updated')));
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text(
          'This will delete the event and all RSVPs. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref
        .read(editEventControllerProvider(widget.eventId).notifier)
        .deleteEvent();

    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Event deleted')));
  }

  /// Mirrors _buildImagePreview from CreateEventPage,
  /// but also shows existing remote image and remove button
  Widget _buildImageSection() {
    final hasNewImage = _newImageFile != null || _newImageBytes != null;
    final hasExistingImage =
        _existingImageUrl != null &&
        _existingImageUrl!.isNotEmpty &&
        !_imageRemoved;
    final hasAnyImage = hasNewImage || hasExistingImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview container — same style as CreateEventPage
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImagePreview(hasNewImage, hasExistingImage),
          ),
        ),

        // Remove button — only shown when there's an image
        if (hasAnyImage) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _removeImage,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Remove Image',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview(bool hasNewImage, bool hasExistingImage) {
    // New image picked on web
    if (kIsWeb && _newImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_newImageBytes!, fit: BoxFit.cover),
      );
    }

    // New image picked on mobile
    if (!kIsWeb && _newImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_newImageFile!, fit: BoxFit.cover),
      );
    }

    // Existing remote image from Firestore
    if (hasExistingImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, _, _) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Could not load image'),
            ],
          ),
        ),
      );
    }

    // No image — same placeholder as CreateEventPage
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
        SizedBox(height: 8),
        Text('Tap to add an image'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));
    final editState = ref.watch(editEventControllerProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Event',
            onPressed: editState.isLoading ? null : _deleteEvent,
          ),
        ],
      ),
      body: eventAsync.when(
        data: (event) {
          _initializeFields(event);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ✅ Image section
                _buildImageSection(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Enter a description' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter a location' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDate == null
                        ? 'Pick date & time'
                        : DateFormat(
                            'MMMM d, y - h:mm a',
                          ).format(_selectedDate!),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickDate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: editState.isLoading ? null : _submit,
                  child: editState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
