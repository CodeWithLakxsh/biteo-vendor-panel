# Environment

## Variables

| Variable | Used by | Where | Template | Notes |
| --- | --- | --- | --- | --- |
| `RAZORPAY_KEY_ID` | Cloud Functions (payments) | `functions/.env` | `functions/.env.example` | Required by the payments function at runtime |
| `RAZORPAY_KEY_SECRET` | Cloud Functions (payments) | `functions/.env` | `functions/.env.example` | Secret. **Never commit.** |
| `GOOGLE_SERVICES_JSON` | CI (Android build) | GitHub Actions secret | — | Full contents of `android/app/google-services.json` |

## Rules

- `functions/.env` and root `.env` are **local-only**; both are gitignored
  and never committed.
- `.env.example` files contain placeholder values only and are safe to commit.
- The real Razorpay credentials that previously existed in
  `functions/.env` were removed during preparation. **Rotate them**
  (regenerate keys in the Razorpay dashboard) since they may have been
  exposed during earlier development.

## Firebase client config

`android/app/google-services.json` is gitignored. A placeholder template is
provided at `android/app/google-services.json.example`. Firebase Android/Web
client identifiers are **public configuration**, not secrets — however they
must still be kept consistent with the registered apps (see
`docs/deployment.md`).
