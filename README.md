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

---

*Later phases will add calendar integration and higher-level agentic flows.*
