# Development

## Prerequisites

- Flutter SDK `>=3.38.4` (Dart `^3.11.4`)
- Android Studio / Android SDK for Android builds
- Node.js 24 + npm (Functions)
- Firebase CLI (`firebase-tools`) and Dart SDK for
  `flutterfire configure`

> Note: Flutter/Dart and the Firebase CLI were **not** available in the
> repository preparation environment. Code-quality and build gates are
> validated in CI (`flutter analyze`, `flutter test`, `flutter build apk
> --debug`, `flutter build web --release`, functions `npm ci`, secret scan).

## Setup

```sh
flutter pub get
cd functions && npm ci && cd ..
flutter run
```

Before running, configure Firebase as described in `docs/deployment.md`
(register the Android app, place `google-services.json`, run
`flutterfire configure`).

## Configuration

Environment variables are documented in `docs/environment.md`. Templates
live at `.env.example` and `functions/.env.example`; copy them to real
files locally but never commit real values.

## Commands

| Task | Command |
| --- | --- |
| Analyze | `flutter analyze` |
| Test | `flutter test` |
| Android debug APK | `flutter build apk --debug` |
| Web release | `flutter build web --release` |
| Functions deps | `cd functions && npm ci` |
| Secret scan | `.github/scripts/secret-scan.sh` |

## Conventions

- Follow existing file structure and naming (screens under `lib/screens/`,
  shared logic under `lib/utils/`).
- Keep pure logic in `lib/utils/formatters.dart` so it stays unit-testable.
- Do not add codegen/build_runner.
- Do not commit secrets, `.env`, or `google-services.json`.
- Commit style: conventional-ish, e.g. `chore: prepare Biteo Vendor Panel for v1.0.0`.

## Testing

`test/widget_test.dart` covers the shared formatters with pure Dart/flutter
tests (no Firebase required). Add tests there for any new pure helpers.
