# Firebase App Check Setup Guide

This document describes how to enable Firebase App Check for production security.
App Check ensures only legitimate app instances can access your Firebase resources.

## Current Status

App Check is **disabled** for development. The encryption key is fetched directly
from Firestore without App Check verification.

## Why Enable App Check?

Without App Check, anyone who obtains your Firebase configuration (`google-services.json`
or `GoogleService-Info.plist`) could potentially:
- Read your encryption key from Firestore
- Access other Firebase resources

With App Check enabled:
- Only your real app (signed with your certificates) can access Firebase
- Requests from emulators, modified APKs, or other sources are rejected

## Setup Steps

### 1. Firebase Console Configuration

#### Android (Play Integrity)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **App Check** (Build section)
4. Click **Apps** tab
5. Select your **Android app**
6. Choose **Play Integrity** as provider
7. Click **Save**

#### iOS (App Attest)
1. In Firebase Console → App Check → Apps
2. Select your **iOS app**
3. Choose **App Attest** as provider
4. Click **Save**

### 2. Enable Enforcement

1. In Firebase Console → App Check → **APIs** tab
2. Find **Cloud Firestore**
3. Click **Enforce**

> **Warning**: After enforcement, requests without valid App Check tokens will be rejected.
> Make sure your app is updated and working before enabling enforcement.

### 3. Code Changes

#### Uncomment App Check in `bootstrap.dart`:

```dart
// Change from:
// import 'package:firebase_app_check/firebase_app_check.dart';

// To:
import 'package:firebase_app_check/firebase_app_check.dart';
```

```dart
// Change from:
// await FirebaseAppCheck.instance.activate(
//   androidProvider: kDebugMode
//       ? AndroidProvider.debug
//       : AndroidProvider.playIntegrity,
//   appleProvider: kDebugMode
//       ? AppleProvider.debug
//       : AppleProvider.appAttest,
// );

// To:
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity,
  appleProvider: kDebugMode
      ? AppleProvider.debug
      : AppleProvider.appAttest,
);
```

### 4. Debug Tokens (Development)

When running in debug mode, App Check uses debug tokens instead of device attestation.

#### Get Debug Token
Run the app in debug mode. Look for this log:
```
D/Firebase: Firebase App Check debug token: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### Register Debug Token
1. Firebase Console → App Check → Apps
2. Click overflow menu (⋮) on your app
3. Select **Manage debug tokens**
4. Click **Add debug token**
5. Paste the token from console

### 5. Firestore Security Rules

Update your Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Config collection - read only
    // App Check validates at network level when enforcement is enabled
    match /config/{document} {
      allow read: if true;
      allow write: if false;
    }

    // Your other rules...
  }
}
```

## Testing

### Before Enforcement
1. Enable App Check in code
2. Test on real devices and emulators
3. Verify debug tokens work
4. Test on release builds

### After Enforcement
1. Enable enforcement in Firebase Console
2. Verify real app still works
3. Verify requests from unauthorized sources fail

## Rollback

If issues occur after enabling enforcement:
1. Go to Firebase Console → App Check → APIs
2. Click on Cloud Firestore
3. Select **Unenforced**

## Providers Comparison

| Provider | Platform | Requirements |
|----------|----------|--------------|
| Play Integrity | Android | Google Play Services |
| App Attest | iOS 14+ | Device with Secure Enclave |
| DeviceCheck | iOS 11+ | Fallback for older iOS |
| Debug | Both | Development only |

## Troubleshooting

### "App Check token is invalid"
- Ensure debug token is registered (for debug builds)
- Ensure app is signed correctly (for release builds)
- Check Firebase project matches

### "Missing or insufficient permissions"
- App Check enforcement may be blocking requests
- Verify App Check is properly initialized before Firestore calls

### iOS Simulator Issues
- App Attest doesn't work on simulators
- Use debug provider for simulators
- Register simulator's debug token

## Files Modified for App Check

| File | Change |
|------|--------|
| `pubspec.yaml` | `firebase_app_check: ^0.3.2+2` |
| `android/app/build.gradle.kts` | Play Integrity dependency |
| `lib/bootstrap.dart` | App Check initialization (commented) |

## References

- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [Flutter Firebase App Check](https://firebase.flutter.dev/docs/app-check/overview/)
- [Play Integrity API](https://developer.android.com/google/play/integrity)
- [App Attest](https://developer.apple.com/documentation/devicecheck/establishing_your_app_s_integrity)
