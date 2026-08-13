# Deployment

## Overview

The app targets Firebase project **`biteo-1e76d`** (project number
`476619872302`). Application ID is **`in.biteo.vendor`**.

## Required Firebase app registrations

The following are **blockers** and must be completed before a working build
can be produced. Do not fabricate configuration values.

### Android — `in.biteo.vendor` (REQUIRED, pending)

The applicationId was renamed to `in.biteo.vendor`, but no Firebase Android
app exists with that package yet. Until it is registered:

1. In the Firebase console (project `biteo-1e76d`), add an Android app with
   package `in.biteo.vendor`.
2. Download `google-services.json` and place it at
   `android/app/google-services.json`.
3. Run `flutterfire configure -p biteo-1e76d` to regenerate
   `lib/firebase_options.dart` (the Android `appId` in the current file
   reflects the old registration and **must** be refreshed).

### Web — app registration (PENDING)

The Web app's `apiKey`/`appId`/`authDomain` are not recoverable from this
repository; they are marked `PENDING_WEB_*` in `lib/firebase_options.dart`.
Register/confirm the Web app in the Firebase console, then run
`flutterfire configure`.

### iOS — not configured

No `GoogleService-Info.plist` and no Podfile are present. iOS is not a
release target yet.

## CI

`.github/workflows/ci.yml` runs on a clean checkout:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` (uses `GOOGLE_SERVICES_JSON` secret to create
  `android/app/google-services.json`)
- `flutter build web --release`
- `cd functions && npm ci`
- secret scan gate

Configure the GitHub secret `GOOGLE_SERVICES_JSON` with the contents of
`android/app/google-services.json`.

## Cloud Functions

```sh
cd functions
cp .env.example .env    # fill RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET
npm ci
firebase use biteo-1e76d
firebase deploy --only functions
```

## Release signing (Android)

`android/app/build.gradle.kts` reads `android/key.properties` for the release
signing config when present, otherwise it falls back to the debug signing
config for convenience. **PRODUCTION SIGNING IS NOT CONFIGURED.** Create
`android/key.properties` (gitignored) with `storeFile`, `storePassword`,
`keyAlias`, `keyPassword` before publishing.

## Release process (future)

After all CI gates pass and the tree is clean:

1. Tag: `git tag v1.0.0`
2. Produce `biteo-vendor-panel-v1.0.0.zip` from the clean source tree.
3. Generate `SHA256SUMS.txt` alongside the zip.
4. Write release notes.
