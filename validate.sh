#!/usr/bin/env bash
# Regenerate YANG schema trees and validate JSON examples.
# Requires yanglint from libyang: https://github.com/CESNET/libyang

set -euo pipefail

YANG_DIR="yang"
YANG_LIB="${YANG_DIR}/yang-lib-bmptm.xml"
EXAMPLES_DIR="examples"

# Auto-detect the main module (latest revision by sort order)
MAIN_MODULE=$(ls "${YANG_DIR}"/ietf-bmp-telemetry-message@*.yang 2>/dev/null | sort | tail -1)
if [[ -z "$MAIN_MODULE" ]]; then
  echo "ERROR: No ietf-bmp-telemetry-message@*.yang found in ${YANG_DIR}/" >&2
  exit 1
fi
MODULE_BASE="${MAIN_MODULE%.yang}"

echo "Module: ${MAIN_MODULE}"

# ── Schema trees ─────────────────────────────────────────────────────────────
echo
echo "==> Generating schema trees..."
yanglint -e -Y "$YANG_LIB" -p ${YANG_DIR} "$MAIN_MODULE" --tree-line-length 69 -f tree \
    > "${YANG_DIR}/tree-L69-bmptm.txt"
echo "    ${YANG_DIR}/tree-L69-bmptm.txt"

yanglint -e -Y "$YANG_LIB" -p ${YANG_DIR} "$MAIN_MODULE" -f tree \
    > "${YANG_DIR}/tree-bmptm.txt"
echo "    ${YANG_DIR}/tree-bmptm.txt"

# ── Example validation ────────────────────────────────────────────────────────
echo
echo "Validating examples..."
PASS=0; FAIL=0
for example in "${EXAMPLES_DIR}"/*.json; do
  [[ -f "$example" ]] || continue
  if yanglint -e -Y "$YANG_LIB" -p ${YANG_DIR} "$example" -f json 2>/dev/null; then
    echo "  PASS  $example"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $example"
    yanglint -e -Y "$YANG_LIB" -p ${YANG_DIR} "$example" -f json
    FAIL=$((FAIL + 1))
  fi
done

echo
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]]