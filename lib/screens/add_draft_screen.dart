import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/persistence/drafts_store.dart';
import '../core/persistence/event_draft.dart';
import '../core/vision/mlkit_text_extractor.dart';

/// Phase II–III: Multimodal input — manual, camera, and on-device OCR (ML Kit).
/// Pass [existingDraft] to edit an existing draft instead of creating a new one.
class AddDraftScreen extends StatefulWidget {
  const AddDraftScreen({super.key, required this.draftsStore, this.existingDraft});

  final DraftsStore draftsStore;
  final EventDraft? existingDraft;

  @override
  State<AddDraftScreen> createState() => _AddDraftScreenState();
}

class _AddDraftScreenState extends State<AddDraftScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _locationController;
  String? _attachmentPath;
  DraftSource? _source;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existingDraft != null;

  static final _dateFormat = DateFormat('EEEE, MMMM d');
  static final _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    final draft = widget.existingDraft;
    _titleController = TextEditingController(text: draft?.title ?? '');
    _bodyController = TextEditingController(text: draft?.body ?? '');
    _locationController = TextEditingController(text: draft?.location ?? '');
    _attachmentPath = draft?.attachmentPath;
    _source = draft?.source ?? DraftSource.manual;
    _startAt = draft?.startAt;
    _endAt = draft?.endAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _chooseSource(DraftSource source) async {
    setState(() {
      _source = source;
      _error = null;
    });
    switch (source) {
      case DraftSource.manual:
        break;
      case DraftSource.camera:
        await _captureWithCamera();
        break;
    }
  }

  Future<void> _captureWithCamera() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null || !mounted) return;
      await _processImage(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      await _processImage(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery error: $e')),
      );
    }
  }

  Future<void> _processImage(String imagePath) async {

    // Let user crop the image before we store & OCR it.
    final cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop image',
          toolbarColor: Theme.of(context).colorScheme.surface,
          toolbarWidgetColor: Theme.of(context).colorScheme.primary,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop image',
        ),
      ],
    );

    final pathToUse = cropped?.path ?? imagePath;
    setState(() => _attachmentPath = pathToUse);

    // Phase III: run on-device OCR and let the user review/edit the result.
    final extracted = await MlkitTextExtractor.instance
        .extractTextFromImageFile(File(pathToUse));
    if (!mounted || extracted == null || extracted.isEmpty) return;

    final reviewed = await _reviewExtractedText(extracted);
    if (!mounted || reviewed == null || reviewed.trim().isEmpty) return;
    setState(() {
      _bodyController.text = reviewed.trim();
    });
  }

  /// Lets the user review and optionally edit OCR text before using it.
  Future<String?> _reviewExtractedText(String text) async {
    final controller = TextEditingController(text: text);
    String? result;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recognized text'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              result = controller.text;
              Navigator.of(context).pop();
            },
            child: const Text('Use text'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = isStart ? _startAt : _endAt;
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (pickedTime == null || !mounted) return;
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      if (isStart) {
        _startAt = combined;
        if (_endAt == null || _endAt!.isBefore(combined)) {
          _endAt = combined.add(const Duration(hours: 1));
        }
      } else {
        _endAt = combined.isAfter(_startAt ?? now)
            ? combined
            : (_startAt ?? now).add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _save() async {
    final source = _source ?? DraftSource.manual;
    setState(() => _saving = true);
    final title = _titleController.text.trim().isEmpty ? null : _titleController.text.trim();
    final body = _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim();
    final location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();

    EventDraft draft;
    if (_isEditing) {
      draft = widget.existingDraft!.copyWith(
        source: source,
        title: title,
        body: body,
        attachmentPath: _attachmentPath,
        location: location,
        startAt: _startAt,
        endAt: _endAt,
        updatedAt: DateTime.now(),
      );
      await widget.draftsStore.update(draft);
    } else {
      draft = EventDraft(
        source: source,
        title: title,
        body: body,
        attachmentPath: _attachmentPath,
        location: location,
        startAt: _startAt,
        endAt: _endAt,
        createdAt: DateTime.now(),
      );
      await widget.draftsStore.insert(draft);
    }
    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final startDisplay = _startAt ?? now;
    final endDisplay = _endAt ?? startDisplay.add(const Duration(hours: 1));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit event' : 'New event'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(_error!, style: TextStyle(color: colorScheme.error)),
              ),

            // ── Input source (Camera / Upload) ──
            _SectionTile(
              icon: Icons.attach_file,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text('Add input via', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Camera'),
                        onPressed: () => _chooseSource(DraftSource.camera),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Upload'),
                        onPressed: _uploadImage,
                      ),
                    ],
                  ),
                  if (_attachmentPath != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_attachmentPath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                            onPressed: () => setState(() => _attachmentPath = null),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(height: 1, indent: 56),

            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: TextField(
                controller: _titleController,
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  hintText: 'Add title',
                  hintStyle: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 1),

            // ── Date & Time ──
            _SectionTile(
              icon: Icons.access_time,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _pickDateTime(isStart: true),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _dateFormat.format(startDisplay),
                            style: theme.textTheme.bodyLarge,
                          ),
                          Text(
                            '${_timeFormat.format(startDisplay)}  –  ${_timeFormat.format(endDisplay)}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_startAt != null || _endAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            'Does not repeat',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() {
                              _startAt = null;
                              _endAt = null;
                            }),
                            child: Text(
                              'Clear',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Tap to set date & time',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 56),

            // ── Location ──
            _SectionTile(
              icon: Icons.location_on_outlined,
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Add location',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 1, indent: 56),

            // ── Description ──
            _SectionTile(
              icon: Icons.notes,
              child: TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  hintText: 'Add description',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                ),
                style: theme.textTheme.bodyLarge,
                maxLines: 4,
                minLines: 1,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, right: 16),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
