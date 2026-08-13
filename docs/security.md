# Security

## Secrets policy

- **Never commit** `.env`, `functions/.env`, `android/app/google-services.json`,
  `**/GoogleService-Info.plist`, `key.properties`, keystores/keyboxes, or any
  credentials.
- Real Razorpay credentials that existed in `functions/.env` were removed
  during preparation. **Rotate them** in the Razorpay dashboard.
- `.env.example` files contain placeholders only and are safe to commit.
- Firebase client identifiers (API keys, app IDs in `google-services.json`
  / `firebase_options.dart`) are **public client configuration**, not server
  secrets. They are kept in the repository only as reconstruction of the
  registered client config and are refreshed via `flutterfire configure`.

## Gitignore coverage

- `.env`, `.env.*` (with `!.env.example`)
- `functions/.env.*` (with `!functions/.env.example`)
- `android/app/google-services.json`
- `**/GoogleService-Info.plist`
- `key.properties`, `**/*.keystore`, `*.jks`, `*.keybox`
- build caches and local IDE files

## Secret scan

CI runs `.github/scripts/secret-scan.sh` (and the workflow references
`.gitleaks.toml`) to fail on: Razorpay live/test keys, Stripe keys, private
keys, service-account credentials, JWTs, and forbidden file paths (`.env`,
keystores). Firebase client identifiers are intentionally not classified as
server secrets.

## Known limitations — REQUIRES FUTURE ARCHITECTURAL CHANGE

These items are documented here because they are **not fixed** by repository
preparation. They must be addressed before production use:

1. **Firestore/Storage security rules.** No `firestore.rules` /
   `storage.rules` are present in this repository. Data-access is not locked
   down; implement rules that scope access to the authenticated vendor and
   their storefront, and deploy them to the project.
2. **Payment verification.** Payment verification is a Cloud Function using
   the Razorpay SDK with credentials in `functions/.env`. Review and harden
   signature verification and error handling before production.
3. **Notification authorization.** Runtime permission requests for
   notifications exist, but the full permission flow and handling of
   `POST_NOTIFICATIONS` should be tested on Android 13+ and documented.
4. **Backend authentication.** Client-side Firestore reads are broad; any
   vendor can attempt to read any document path it can guess. Security rules
   (item 1) are the mitigation.
5. **Release signing.** No release keystore configured; production signing
   must be set up via `android/key.properties`.

## Checklist before publishing

- [ ] Rotate any previously exposed Razorpay credentials
- [ ] Register the `in.biteo.vendor` Firebase Android app and refresh
      `firebase_options.dart` + `google-services.json`
- [ ] Author and deploy Firestore/Storage security rules
- [ ] Configure release signing
- [ ] Run the CI secret-scan gate and confirm a clean pass
- [ ] Review the release artifact (`SHA256SUMS.txt`) contents
