# Biteo Vendor Panel

Vendor/restaurant management platform for the Biteo ecosystem.

Manage live orders, menu items, daily earnings, and profile settings from a
single mobile panel. Built with Flutter and Firebase.

## App purpose and features

- Vendor login (phone + password) via Firebase Authentication
- Live dashboard with today's orders, revenue, and menu stats
- Real-time order stream with audio notifications for new orders
- Order status workflow (pending → accepted → preparing → ready → completed)
- Menu management with image uploads (Firebase Storage)
- Razorpay payment verification via Cloud Functions
- Vendor profile and support screens

## Screenshots

_To be added._

## Tech stack

- Flutter (Dart) — Material Design 3 UI
- Firebase: Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging
- Cloud Functions for Node.js (firebase-admin, firebase-functions, razorpay)
- Razorpay payments
- `audioplayers`, `image_picker`, `flutter_local_notifications`,
  `firebase_ui_auth`, `intl`

## Repository structure

```
biteo_vendor_panel/
├── android/                  # Android host (applicationId: in.biteo.vendor)
├── ios/                      # iOS host (not yet release-configured)
├── linux/                    # Linux desktop host
├── macos/                    # macOS desktop host
├── windows/                  # Windows desktop host
├── web/                      # Web host (Firebase Web app not yet registered)
├── functions/                # Cloud Functions (Node.js 24)
│   ├── index.js
│   ├── .env.example          # Template: RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET
│   └── package.json
├── lib/
│   ├── main.dart             # Entry point, Firebase.initializeApp
│   ├── firebase_options.dart # Firebase options (project biteo-1e76d)
│   ├── screens/              # login, dashboard, orders, menu, profile, support
│   └── utils/formatters.dart # Shared pure formatting helpers (unit tested)
├── test/widget_test.dart     # Firebase-free unit tests
├── android/app/google-services.json.example  # Template (never commit the real file)
├── docs/                     # Architecture, development, deployment, env, security
├── .github/workflows/ci.yml  # CI: analyze, test, build apk/web, functions, secret scan
└── .gitignore
```

## Local development

### Prerequisites

- Flutter SDK (`>=3.38.4`) with Dart `^3.11.4`
- Android Studio / Android SDK for Android builds
- Node.js 24 and npm
- Firebase CLI (`firebase-tools`) for Functions deploy and
  `flutterfire configure`
- A Firebase account with access to project `biteo-1e76d`

### Setup

1. Clone the repository and run `flutter pub get`.
2. Install Functions dependencies: `cd functions && npm ci`.
3. Configure Firebase for your local project:

   - Register the Android app with package `in.biteo.vendor` in the Firebase
     console (project `biteo-1e76d`) and download `google-services.json` into
     `android/app/`.
   - Run `flutterfire configure -p biteo-1e76d` to regenerate
     `lib/firebase_options.dart` (required: the current file is marked
     `PENDING_*`/reconstructed and must be refreshed before running).
   - Web/iOS require registering the corresponding Firebase apps first; see
     `docs/deployment.md`.

4. Configure environment variables (copy the templates, never commit real
   values):

   - `functions/.env.example` → `functions/.env`
   - `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` are consumed by Cloud
     Functions only.

5. Run the app:

   ```sh
   flutter run
   ```

### Validation

Local Flutter/Dart and Firebase CLI tooling were not available in the
preparation environment, so `flutter analyze`, `flutter test`, and build gates
are validated in CI (see `.github/workflows/ci.yml`). CI injects
`android/app/google-services.json` from the `GOOGLE_SERVICES_JSON` secret.

- Analyze: `flutter analyze`
- Test: `flutter test`
- Android debug build: `flutter build apk --debug`
- Web release build: `flutter build web --release`

## Application identity

- Application ID / package: `in.biteo.vendor`
- Firebase project: `biteo-1e76d`
- Versioning: Semantic Versioning (`1.0.0+1`), tagged `v1.0.0`

## Future work

- Register the `in.biteo.vendor` Firebase Android app and refresh Firebase
  client configuration (see `docs/deployment.md` for blockers).
- Add a release signing configuration (`android/key.properties`).
- Notifications, payment, and data-access hardening
  (see `docs/security.md`).
- iOS build configuration.

## License

[MIT](LICENSE)
