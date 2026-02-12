import 'package:flutter/material.dart';

import '../core/persistence/drafts_store.dart';
import '../core/persistence/event_draft.dart';
import '../core/identity/auth_service.dart';
import '../core/nlp/mlkit_intent_extractor.dart';
import '../core/calendar/google_calendar_client.dart';
import 'add_draft_screen.dart';
import 'confirm_event_screen.dart';

/// Phase II: List of locally persisted event drafts + FAB for multimodal input.
class DraftsScreen extends StatefulWidget {
  const DraftsScreen({
    super.key,
    required this.draftsStore,
    required this.auth,
    required this.onSignOut,
  });

  final DraftsStore draftsStore;
  final AuthService auth;
  final VoidCallback onSignOut;

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List<EventDraft> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await widget.draftsStore.getAll();
    if (mounted) {
      setState(() {
        _drafts = list;
        _loading = false;
      });
    }
  }

  Future<void> _openAddDraft() async {
    final created = await Navigator.of(context).push<EventDraft?>(
      MaterialPageRoute(
        builder: (context) => AddDraftScreen(draftsStore: widget.draftsStore),
      ),
    );
    if (created != null && mounted) _load();
  }

  Future<void> _deleteDraft(EventDraft draft) async {
    if (draft.id == null) return;
    await widget.draftsStore.delete(draft.id!);
    if (mounted) _load();
  }

  Future<void> _convertToEvent(EventDraft draft) async {
    final pieces = <String>[];
    if (draft.title != null && draft.title!.trim().isNotEmpty) {
      pieces.add(draft.title!.trim());
    }
    if (draft.body != null && draft.body!.trim().isNotEmpty) {
      pieces.add(draft.body!.trim());
    }
    final rawText = pieces.join('\n').trim();
    if (rawText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft has no text to convert.')),
      );
      return;
    }

    final intent = await MlkitIntentExtractor.instance.extract(rawText);
    if (!mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ConfirmEventScreen(
          intent: intent,
          calendarClient: GoogleCalendarClient(widget.auth),
        ),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created in Google Calendar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onSignOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No drafts yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap + to add via text or camera.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _drafts.length,
                    itemBuilder: (context, index) {
                      final d = _drafts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(_iconFor(d.source)),
                        ),
                        title: Text(d.title ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          d.body ?? (d.attachmentPath != null ? 'Attachment' : '—'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.event_available),
                              tooltip: 'Convert to event',
                              onPressed: () => _convertToEvent(d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteDraft(d),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDraft,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  IconData _iconFor(DraftSource s) {
    switch (s) {
      case DraftSource.manual:
        return Icons.text_fields;
      case DraftSource.camera:
        return Icons.camera_alt;
      case DraftSource.voice:
        return Icons.mic;
    }
  }
}
