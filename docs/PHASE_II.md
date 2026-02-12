# Phase II: Multimodal Input and Local Persistence

Phase II adds input modalities and local storage so user data (settings and pending event drafts) remains intact if a process is interrupted—e.g. during complex NLP extraction in a later phase.

## Implemented

### Input modalities

- **Manual:** Title and notes via text fields
- **Camera:** Capture a photo via `image_picker` (camera); image path stored with the draft
- **Voice:** Record audio via `record`; recording file path stored with the draft

### Local persistence

- **Event drafts:** `DraftsStore` (SQLite via `sqflite`) in `lib/core/persistence/drafts_store.dart`
  - Table: `drafts` (id, source, title, body, attachment_path, created_at, updated_at)
  - Drafts are inserted when the user saves from the Add screen; list is shown on the Drafts screen
- **User settings:** `SettingsStore` (key-value via `shared_preferences`) in `lib/core/persistence/settings_store.dart`
  - Available for app preferences; can be extended for e.g. default reminder time, theme

### UI

- **Drafts screen:** Home after sign-in; lists drafts, FAB **Add** opens the add-draft flow
- **Add draft screen:** Choose Type / Camera / Voice; optional title and notes; optional attachment (image or voice file); **Save** persists to SQLite

### Permissions

- **Android:** `CAMERA`, `RECORD_AUDIO` in `AndroidManifest.xml`
- **iOS:** `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription` in `Info.plist`

## Usage

1. Sign in (Phase I).
2. On the drafts list, tap **Add**.
3. Choose **Type**, **Camera**, or **Voice** (camera/voice capture immediately; type is always available).
4. Optionally set title and notes; for camera/voice an attachment is stored.
5. Tap **Save** to persist the draft locally.

Drafts are stored on the device only; calendar sync and NLP extraction are planned for later phases.
