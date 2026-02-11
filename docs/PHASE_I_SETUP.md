# Phase I: Foundation and Identity Management — Setup

This document covers the one-time configuration required for **Phase I** of SmartSchedule: Firebase, Google Sign-In, and secure communication with the Google Authorization Server. The app uses a **no-backend** architecture: authentication is the mechanism to obtain short-lived tokens the mobile client uses to call third-party APIs (e.g. Google Calendar) directly.

---

## 1. Firebase project and FlutterFire CLI

1. Create a [Firebase project](https://console.firebase.google.com/) (or use an existing one).
2. Install and run the FlutterFire CLI from the project root:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   If the CLI fails with `UnsupportedError not found in web`, run it again and select only **Android** and **iOS** (deselect web, windows, macos); that avoids the crash and still generates the config you need for mobile.

   This will:

   - Link the Flutter app to your Firebase project
   - Generate `lib/firebase_options.dart` with platform-specific config
   - Add Android `google-services.json` and iOS `GoogleService-Info.plist`
   - Register the Android and iOS apps in Firebase if needed

3. In [Firebase Console → Authentication](https://console.firebase.google.com/project/_/authentication/providers), enable the **Google** sign-in provider.

---

## 2. Android: SHA-1 fingerprint

Google Sign-In and the Google Authorization Server use the **SHA-1 fingerprint** of your signing key to validate the app. Without it, sign-in can fail on Android.

### Get your SHA-1

From the project root:

```bash
cd android && ./gradlew signingReport
```

In the output, find the **SHA-1** for the key you use to run the app (e.g. `debug` for development). Copy it.

### Add SHA-1 in Firebase

1. Open [Firebase Console → Project settings](https://console.firebase.google.com/project/_/settings/general).
2. Under **Your apps**, select your **Android** app (package name: `com.smartschedule.smart_schedule`).
3. Click **Add fingerprint** and paste the SHA-1.
4. For release builds, add the SHA-1 of your **release** keystore as well (run `signingReport` with the release keystore configured).

---

## 3. iOS: Client ID and URL scheme

For iOS, the Google Sign-In SDK needs a **reversed client ID** URL scheme so the OAuth flow can return to your app.

### Option A: FlutterFire CLI

If `flutterfire configure` registered your iOS app and downloaded `GoogleService-Info.plist`, it may have configured the URL scheme. Open `ios/Runner/Info.plist` and confirm there is a `CFBundleURLTypes` entry whose `CFBundleURLSchemes` contains the reversed client ID (e.g. `com.googleusercontent.apps.123456789-xxxx`).

### Option B: Manual

1. In [Google Cloud Console](https://console.cloud.google.com/) (same project as Firebase), go to **APIs & Services → Credentials**.
2. Open the **OAuth 2.0 Client ID** of type **iOS** (create one if needed; use your iOS bundle ID: `com.smartschedule.smart_schedule`).
3. Copy the **Client ID** (e.g. `123456789-xxxx.apps.googleusercontent.com`).
4. Reverse it to form the URL scheme: e.g. `com.googleusercontent.apps.123456789-xxxx`.
5. In Xcode (or by editing `ios/Runner/Info.plist`), add a URL type:
   - **URL Schemes**: the reversed client ID from step 4
   - **Role**: Editor (or leave default)

Example `Info.plist` snippet:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID_PREFIX</string>
    </array>
  </dict>
</array>
```

---

## 4. Verify

1. Run the app: `flutter run` (Android or iOS).
2. You should see the Phase I sign-in screen (not the “Firebase is not configured” screen).
3. Tap **Sign in with Google** and complete the flow.
4. After sign-in, the token gateway is ready; `AuthService.getIdToken()` and `AuthService.getAccessToken()` / `getOAuthTokens()` can be used for direct API calls in later phases.

---

## Summary

| Platform | What to configure |
|----------|--------------------|
| **All**  | Firebase project, `flutterfire configure`, enable Google Sign-In in Firebase |
| **Android** | Add SHA-1 fingerprint in Firebase project settings |
| **iOS**  | Add reversed OAuth Client ID as URL scheme in `Info.plist` |

Once this is done, Phase I is complete: identity and short-lived tokens are available for use by the rest of the app and by an agentic bot in later phases.
