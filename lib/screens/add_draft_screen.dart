import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _attachmentPath;
  DraftSource? _source;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existingDraft != null;

  @override
  void initState() {
    super.initState();
    final draft = widget.existingDraft;
    _titleController = TextEditingController(text: draft?.title ?? '');
    _bodyController = TextEditingController(text: draft?.body ?? '');
    _attachmentPath = draft?.attachmentPath;
    _source = draft?.source ?? DraftSource.manual;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
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
      case DraftSource.voice:
        _showVoiceUnavailable();
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

  void _showVoiceUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice recording will be added in a later phase.'),
      ),
    );
  }

  Future<void> _save() async {
    final source = _source ?? DraftSource.manual;
    setState(() => _saving = true);
    final title = _titleController.text.trim().isEmpty ? null : _titleController.text.trim();
    final body = _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim();

    EventDraft draft;
    if (_isEditing) {
      draft = widget.existingDraft!.copyWith(
        source: source,
        title: title,
        body: body,
        attachmentPath: _attachmentPath,
        updatedAt: DateTime.now(),
      );
      await widget.draftsStore.update(draft);
    } else {
      draft = EventDraft(
        source: source,
        title: title,
        body: body,
        attachmentPath: _attachmentPath,
        createdAt: DateTime.now(),
      );
      await widget.draftsStore.insert(draft);
    }
    if (!mounted) return;
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit draft' : 'New draft'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
            ],
            const Text('Add input via:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SourceChip(
                  label: 'Type',
                  icon: Icons.text_fields,
                  selected: source == DraftSource.manual,
                  onTap: () => _chooseSource(DraftSource.manual),
                ),
                _SourceChip(
                  label: 'Camera',
                  icon: Icons.camera_alt,
                  selected: source == DraftSource.camera,
                  onTap: () => _chooseSource(DraftSource.camera),
                ),
                _SourceChip(
                  label: 'Upload',
                  icon: Icons.photo_library,
                  selected: false,
                  onTap: _uploadImage,
                ),
                _SourceChip(
                  label: 'Voice',
                  icon: Icons.mic,
                  selected: source == DraftSource.voice,
                  onTap: () => _chooseSource(DraftSource.voice),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notes / description',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
            if (_attachmentPath != null) ...[
              const SizedBox(height: 16),
              const Text('Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _AttachmentPreview(path: _attachmentPath!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(label)],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.m4a') || path.toLowerCase().endsWith('.aac')) {
      return ListTile(
        leading: const Icon(Icons.audiotrack),
        title: const Text('Voice recording'),
        subtitle: Text(path.split('/').last),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(File(path), height: 120, width: double.infinity, fit: BoxFit.cover),
    );
  }
}
