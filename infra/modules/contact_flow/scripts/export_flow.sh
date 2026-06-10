#!/usr/bin/env bash
# Export a console-authored contact flow as a Terraform template seed.
#
# Usage:
#   ./export_flow.sh <instance-id> <contact-flow-id> <output-name>
#
# Example:
#   ./export_flow.sh 1111-2222 3333-4444 aria_inbound
#   -> writes ../templates/aria_inbound.json.tftpl
#
# Workflow (the bug-avoiding pattern — see module README):
#   1. Author/edit the flow in the Connect console flow designer.
#   2. Run this script to export the known-good JSON.
#   3. MANUALLY replace environment-specific values (queue ARNs, Lex bot alias
#      ARNs, Lambda ARNs, prompt ARNs) with ${placeholder} template vars.
#   4. Pass the placeholders via the module's template_vars.
#
# List flows to find the ID:
#   aws connect list-contact-flows --instance-id <instance-id> \
#     --query 'ContactFlowSummaryList[].{Name:Name,Id:Id}' --output table

set -euo pipefail

if [ $# -ne 3 ]; then
  grep '^# ' "$0" | head -20
  exit 1
fi

INSTANCE_ID="$1"
FLOW_ID="$2"
OUT_NAME="$3"
OUT_DIR="$(cd "$(dirname "$0")/../templates" && pwd)"
OUT_FILE="${OUT_DIR}/${OUT_NAME}.json.tftpl"

aws connect describe-contact-flow \
  --instance-id "${INSTANCE_ID}" \
  --contact-flow-id "${FLOW_ID}" \
  --query 'ContactFlow.Content' \
  --output text | jq . > "${OUT_FILE}"

echo "Exported -> ${OUT_FILE}"
echo
echo "Next: replace environment-specific ARNs with \${placeholders}, e.g.:"
echo '  "LexV2Bot": { "AliasArn": "${lex_bot_alias_arn}" }'
echo "Then wire the placeholders through the module's template_vars."
