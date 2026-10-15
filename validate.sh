#!/usr/bin/env bash
# Regenerate YANG schema trees and validate JSON examples.
# Requires yanglint from libyang (https://github.com/CESNET/libyang) and jq.
#
# Examples are payload-only (ietf-bmp-message, validated standalone); the
# examples/telemetry-message/ ones are full ietf-telemetry-message envelopes.

set -euo pipefail

YANG_DIR="yang"
YANG_LIB="${YANG_DIR}/yang-lib-bmptm.xml"
EXAMPLES_DIR="examples"

latest() { ls "${YANG_DIR}"/"$1"@*.yang 2>/dev/null | sort | tail -1; }

PAYLOAD_MODULE=$(latest ietf-bmp-message)
EXT_MODULE=$(latest ietf-bmp-telemetry-message)
ENVELOPE_MODULE=$(ls "${YANG_DIR}"/deps/ietf-telemetry-message@*.yang 2>/dev/null | sort | tail -1)
for m in "$PAYLOAD_MODULE" "$EXT_MODULE" "$ENVELOPE_MODULE"; do
  if [[ -z "$m" ]]; then
    echo "ERROR: missing module (ietf-bmp-message, ietf-bmp-telemetry-message or ietf-telemetry-message)" >&2
    exit 1
  fi
done

echo "Payload module:   ${PAYLOAD_MODULE}"
echo "Extension module: ${EXT_MODULE}"
echo "Envelope module:  ${ENVELOPE_MODULE}"

# -D: don't search the CWD, which would pick up modules from archive/ or _tmp*/.
YL=(yanglint -D -e -Y "$YANG_LIB" -p "${YANG_DIR}")

# ── Schema trees ─────────────────────────────────────────────────────────────
echo
echo "==> Generating schema trees..."
"${YL[@]}" "$PAYLOAD_MODULE" --tree-line-length 69 -f tree \
    > "${YANG_DIR}/tree-bmp-message-L69.txt"
"${YL[@]}" "$PAYLOAD_MODULE" -f tree > "${YANG_DIR}/tree-bmp-message.txt"
"${YL[@]}" "$ENVELOPE_MODULE" "$EXT_MODULE" --tree-line-length 69 -f tree \
    > "${YANG_DIR}/tree-bmp-telemetry-message-L69.txt"
"${YL[@]}" "$ENVELOPE_MODULE" "$EXT_MODULE" -f tree \
    > "${YANG_DIR}/tree-bmp-telemetry-message.txt"
echo "    ${YANG_DIR}/tree-*bmp-message.txt, ${YANG_DIR}/tree-*bmp-telemetry-message.txt"

# ── Example validation ────────────────────────────────────────────────────────
# examples/*.json           payload only, standalone against ietf-bmp-message
# examples/telemetry-message/*.json  full ietf-telemetry-message envelope with
#   the ietf-bmp-telemetry-message augment. -A parses the anydata payload
#   strictly against the schema (catches bad values, but not missing
#   mandatory nodes), so the payload is also extracted and validated
#   standalone against ietf-bmp-message.
echo
echo "Validating examples..."
PASS=0; FAIL=0
TMP=$(mktemp --suffix=.json)
trap 'rm -f "$TMP"' EXIT

for example in "${EXAMPLES_DIR}"/*.json; do
  [[ -f "$example" ]] || continue
  if "${YL[@]}" "$example" -f json >/dev/null 2>&1; then
    echo "  PASS  $example"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $example"
    "${YL[@]}" "$example" -f json >/dev/null || true
    FAIL=$((FAIL + 1))
  fi
done

for example in "${EXAMPLES_DIR}"/telemetry-message/*.json; do
  [[ -f "$example" ]] || continue
  jq '.["ietf-telemetry-message:message"].payload' "$example" > "$TMP"
  if "${YL[@]}" -A "$example" -f json >/dev/null 2>&1 \
     && "${YL[@]}" "$TMP" -f json >/dev/null 2>&1; then
    echo "  PASS  $example (envelope + payload)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $example"
    echo "  -- envelope:"
    "${YL[@]}" -A "$example" -f json >/dev/null || true
    echo "  -- payload:"
    "${YL[@]}" "$TMP" -f json >/dev/null || true
    FAIL=$((FAIL + 1))
  fi
done

echo
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]]
