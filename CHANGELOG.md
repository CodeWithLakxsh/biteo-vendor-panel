# Changelog

All notable changes to this project are documented in this file.

## [1.0.0]

### Added

- Flutter vendor panel application (Android) with vendor login, live
  dashboard, order management, menu management, vendor profile, and support
  screens.
- Firebase integration (Authentication, Cloud Firestore, Cloud Storage,
  Cloud Messaging) and Cloud Functions for order notifications and Razorpay
  payment verification.
- Audio notifications for new orders (`audioplayers`) and
  `flutter_local_notifications` for in-app alerts.
- Unit tests for shared formatting logic (`lib/utils/formatters.dart`) that
  run without Firebase.

### Changed

- Application ID kept as `com.example.biteo_vendor_panel` (the only registered
  Firebase Android app for project `biteo-1e76d`) so CI can validate against
  the real client config. The target package `in.biteo.vendor` is documented
  in `docs/deployment.md` pending a new Firebase app registration.
- Reconstructed `lib/firebase_options.dart` from the existing Firebase client
  config for project `biteo-1e76d` (values marked for refresh via
  `flutterfire configure` after registering the new Android app).
- Set `.firebaserc` default project to `biteo-1e76d`.
- Enforced secrets hygiene: real Razorpay credentials removed from
  `functions/.env` (rotation recommended), `.env`/`.env.*`/`google-services.json`
  ignored, templates added.
- Removed unused placeholder widget files and duplicate generated artifacts
  (build caches, iOS `Generated`/`flutter_export_environment` duplicates,
  `.DS_Store`, `.iml`).
- Added `INTERNET` (main manifest) and `POST_NOTIFICATIONS` permissions.

### Fixed

- Release builds now keep network access via the main manifest
  `INTERNET` permission.
- Replaced the stale, Firebase-dependent counter smoke test with
  Firebase-free unit tests.

### Security

- Documented `functions/.env` as local-only; never committed.
- Documented that Firebase client identifiers (public config) are not server
  secrets; real credentials are kept out of the repository.
- Added a CI secret scan gate and `.gitleaks` configuration.
- See `docs/security.md` for documented future architectural hardening
  (backend data-access rules, payment handling, notification authorization).
