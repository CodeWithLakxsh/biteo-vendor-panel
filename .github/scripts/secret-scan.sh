#!/usr/bin/env bash
#
# Biteo Vendor Panel secret-scan gate.
#
# Fails when tracked/present files contain:
#   - forbidden file paths (.env, keystores, keys, private keys, service accounts)
#   - Razorpay, Stripe, AWS, GitHub, JWT, or private-key material
#
# Firebase client identifiers (google-services.json / firebase_options.dart)
# are PUBLIC configuration and are intentionally not treated as secrets.
#
# Never print detected secret values: only the path and matched rule.

set -euo pipefail

FAILED=0

# ─────────────────────────────────────────────────────────────
# 1. Collect candidate files (tracked files, else filesystem)
# ─────────────────────────────────────────────────────────────
if git rev-parse --git-dir >/dev/null 2>&1; then
  mapfile -d '' FILES < <(git ls-files -z)
else
  mapfile -d '' FILES < <(find . -type f -not -path './.git/*' -print0)
fi

# ─────────────────────────────────────────────────────────────
# 2. Forbidden file paths
# ─────────────────────────────────────────────────────────────
for f in "${FILES[@]}"; do
  # *.env is forbidden unless it is an *.env.example template
  case "$f" in
    *.env)
      if [[ "$f" != *.env.example ]]; then
        echo "::error::Forbidden tracked file: $f"
        FAILED=1
      fi
      ;;
    *.jks | *.keystore | *.keybox | *.p12 | *.pem | *.ppk)
      echo "::error::Forbidden tracked file: $f"
      FAILED=1
      ;;
    key.properties | id_rsa | id_ed25519 | identity | service_account*.json)
      echo "::error::Forbidden tracked file: $f"
      FAILED=1
      ;;
  esac
done

# ─────────────────────────────────────────────────────────────
# 3. Secret content patterns
#    - Firebase public client identifiers are excluded below.
# ─────────────────────────────────────────────────────────────
# Keep this list in sync with the allowlist for Firebase client config.
EXCLUDE_PATHS=(
  "lib/firebase_options.dart"
  "android/app/google-services.json.example"
  ".github/scripts/secret-scan.sh"
)

is_excluded() {
  local f="$1"
  for ex in "${EXCLUDE_PATHS[@]}"; do
    if [[ "$f" == "$ex" ]]; then
      return 0
    fi
  done
  return 1
}

check_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  # Matches whose value is a known placeholder are fine.
  if grep -E "$pattern" "$file" | grep -qvE 'PENDING_|YOUR_|PASTE_|PLACEHOLDER|CHANGE_ME'; then
    echo "::error::Potential $label in $file (value redacted)"
    FAILED=1
  fi
}

for f in "${FILES[@]}"; do
  if is_excluded "$f"; then
    continue
  fi
  if [[ ! -f "$f" ]]; then
    continue
  fi

  check_pattern "$f" 'rzp_(test|live)_[A-Za-z0-9]{6,}' 'Razorpay key'
  check_pattern "$f" 'sk_(live|test)_[A-Za-z0-9]{10,}' 'Stripe key'
  check_pattern "$f" 'AKIA[0-9A-Z]{16}' 'AWS access key'
  check_pattern "$f" 'ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}' 'GitHub token'
  check_pattern "$f" '-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----' 'private key'
  check_pattern "$f" '"type"[[:space:]]*:[[:space:]]*"service_account"' 'service-account credential'
  check_pattern "$f" 'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}' 'JWT/token'
done

if [[ "$FAILED" -ne 0 ]]; then
  echo "::error::Secret scan failed. Remove or fix the flagged items, then re-run."
  exit 1
fi

echo "Secret scan passed: no secrets found in tracked files."
