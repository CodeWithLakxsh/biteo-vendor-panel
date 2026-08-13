# Architecture

## Overview

Biteo Vendor Panel is a Flutter application that lets a restaurant/vendor
operate their Biteo storefront: accept and manage orders, maintain the menu,
and monitor daily performance. It talks to the Biteo backend through
Firebase (Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging)
and Cloud Functions.

## Application layers

```
lib/
├── main.dart                Entry point; Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)
├── firebase_options.dart    Firebase client configuration (project biteo-1e76d)
├── screens/
│   ├── login_screen.dart          Vendor login (Firebase UI / phone + password)
│   ├── dashboard_screen.dart      Today's orders, earnings, menu stats
│   ├── orders_screen.dart         Real-time order stream, status transitions, audio alert
│   ├── menu_screen.dart           CRUD for menu items + image upload
│   ├── vendor_profile_screen.dart Vendor details
│   └── vendor_support_screen.dart Support / contact
└── utils/
    └── formatters.dart     Shared pure helpers (price, status label/color) — unit tested
```

## Data flow

1. Vendor authenticates via Firebase Authentication.
2. The app subscribes to Firestore streams (orders, menu, dashboard stats)
   using `StreamBuilder`.
3. Order status updates are written to Firestore from the Orders screen;
   Cloud Functions listen for state changes to notify vendors.
4. New-order alerts play a sound (`audioplayers`) and show a local
   notification (`flutter_local_notifications`).
5. Menu image uploads go to Firebase Storage; payments are verified by a
   Cloud Function using the Razorpay SDK.

## Cloud Functions (`functions/`)

- Node.js 24 (`functions/package.json`).
- Dependencies: `firebase-admin`, `firebase-functions`, `cors`, `razorpay`.
- Payment and notification triggers read Razorpay credentials from
  `functions/.env` (local only — see `docs/environment.md`).

## Key decisions

- **No code generation.** No Freezed / build_runner; no generated
  `.g.dart` files. Avoids a codegen step in CI.
- **Application ID.** Renamed to `in.biteo.vendor` (a new Firebase Android
  app must be registered under this package — see `docs/deployment.md`).
- **Firebase options.** Reconstructed from the existing registered client
  config; web/iOS values are `PENDING_*` until the corresponding Firebase
  apps are registered.
- **Pure logic extracted** into `lib/utils/formatters.dart` so it can be
  unit-tested without Firebase.

## Platform hosts

- Android: primary target; signing config supports a release keystore via
  `android/key.properties` (see `docs/deployment.md`).
- iOS/macOS/Linux/Windows: bundle identifiers updated; iOS is not yet
  release-configured (no `GoogleService-Info.plist`, no Podfile).
- Web: build configured, but no Firebase Web app registered yet.
