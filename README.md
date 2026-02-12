# SmartSchedule

Flutter app with phase-based development for agentic bot integration. Unified codebase with native access via platform channels; identity and OAuth 2.0 act as a **token gateway** for no-backend, direct third-party API use (e.g. Google Calendar).

## Phase I: Foundation and Identity Management ✅

- **Firebase** + **Google Sign-In** as the primary identity and OAuth 2.0 gateway
- **No-backend**: short-lived tokens from the client for direct API calls
- **AuthService** in `lib/core/identity/auth_service.dart` exposes:
  - `signInWithGoogle()` / `signOut()`
  - `authStateChanges` stream
  - `getIdToken()`, `getAccessToken()`, `getOAuthTokens()` for API clients

### Setup

1. **Configure Firebase and run the app:** see **[docs/PHASE_I_SETUP.md](docs/PHASE_I_SETUP.md)** for:
   - `flutterfire configure` and Firebase project setup
   - **Android:** SHA-1 fingerprint in Firebase project settings
   - **iOS:** OAuth Client ID and URL scheme in `Info.plist`

2. **Run:** `flutter run` (after configuration, use an Android or iOS device/emulator).

## Phase II: Multimodal Input and Local Persistence ✅

- **Input modalities:** manual typing, camera capture (with placeholder for voice in a later phase)
- **Local persistence:**
  - **SQLite** (`lib/core/persistence/drafts_store.dart`) for pending event drafts — data survives process interruption (e.g. during NLP extraction)
  - **Key-value** (`lib/core/persistence/settings_store.dart`) for user settings
- **Drafts screen:** list of drafts, FAB to add via Type / Camera; drafts are persisted locally and visible after sign-in.

### Setup

- **Permissions:** Camera is declared for Android (`AndroidManifest.xml`) and iOS (`Info.plist`). Grant when prompted.
- **Run:** After Phase I sign-in, use **Add** to create drafts with text or camera; they are persisted locally.

---

## Phase III: On-device Vision and OCR ✅

- **Camera + OCR:** When you capture an image for a draft, Google ML Kit Text Recognition runs on-device and proposes recognized text (printed or simple handwriting, Latin scripts) to prefill the notes field. You can review and edit the extracted text before saving.
- **Extensible:** The OCR pipeline lives in `lib/core/vision/mlkit_text_extractor.dart`, so you can swap in advanced vision LLMs (e.g. Qwen2.5-VL) or add more ML Kit language models without touching the UI.

---

*Upcoming phases will add calendar integration and higher-level agentic flows.*
