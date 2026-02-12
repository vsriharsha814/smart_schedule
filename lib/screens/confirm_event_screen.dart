import 'package:flutter/material.dart';

import '../core/calendar/google_calendar_client.dart';
import '../core/nlp/event_intent.dart';

/// Phase V: human-in-the-loop event confirmation/edit screen.
class ConfirmEventScreen extends StatefulWidget {
  const ConfirmEventScreen({
    super.key,
    required final EventIntent intent,
    required this.calendarClient,
  }) : initialIntent = intent;

  final EventIntent initialIntent;
  final GoogleCalendarClient calendarClient;

  @override
  State<ConfirmEventScreen> createState() => _ConfirmEventScreenState();
}

class _ConfirmEventScreenState extends State<ConfirmEventScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _start;
  late DateTime _end;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialIntent.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialIntent.description ?? widget.initialIntent.rawText);
    _locationController =
        TextEditingController(text: widget.initialIntent.location ?? '');
    _start = widget.initialIntent.start ?? DateTime.now();
    _end = widget.initialIntent.end ?? _start.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) return;
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      if (isStart) {
        _start = combined;
        if (_end.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = combined.isAfter(_start) ? combined : _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final intent = widget.initialIntent.copyWith(
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      start: _start,
      end: _end,
    );

    try {
      await widget.calendarClient.createEvent(intent);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Details',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  helperText: widget.initialIntent.locationRequired
                      ? 'Location required for this event.'
                      : 'Optional',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDateTime(isStart: true),
                      child: Text('Start: ${_start.toLocal()}'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDateTime(isStart: false),
                      child: Text('End:   ${_end.toLocal()}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

