#!/usr/bin/env bash
# Deploy the Aria wealth MCP server to Amazon Bedrock AgentCore Runtime.
#
# First run: agentcore create --protocol MCP scaffolds agentcore/agentcore.json
#            and prompts for a project name — answer once, then re-run to deploy.
# Every run: agentcore deploy packages the code, uploads to S3, and creates/updates
#            the runtime. The runtime ARN is printed to stdout.
#
# Prerequisite: Node.js ≥ 18, AWS credentials with bedrock-agentcore:* permissions.
#
# After deploy, register the runtime ARN in agents/concierge/setup_agent.py as a
# toolConfiguration endpoint, then re-run setup_agent.py to wire it to Connect.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. Prerequisites ────────────────────────────────────────────────────────────
command -v node >/dev/null 2>&1 || {
  echo "ERROR: Node.js is required (https://nodejs.org). Install Node ≥ 18."
  exit 1
}

if ! command -v agentcore >/dev/null 2>&1; then
  echo "Installing AgentCore CLI..."
  npm install -g @aws/agentcore
fi

# Verify AWS credentials are available
if ! aws sts get-caller-identity --query Account --output text >/dev/null 2>&1; then
  echo "ERROR: AWS credentials not configured. Run: aws configure"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}
echo "Deploying as account ${ACCOUNT_ID} in ${REGION}"

# ── 2. One-time scaffold ─────────────────────────────────────────────────────────
# agentcore create is interactive — run once; subsequent runs skip straight to deploy.
if [ ! -f "agentcore/agentcore.json" ]; then
  echo ""
  echo "First-time setup: scaffolding AgentCore project."
  echo "When prompted:"
  echo "  Protocol  → MCP  (pre-selected via --protocol flag)"
  echo "  Name      → aria-wealth-tools  (or any name you like)"
  echo "  Entrypoint → wealth_mcp_server.py"
  echo ""
  agentcore create --protocol MCP
  echo ""
  echo "Scaffold complete. Re-running deploy now..."
fi

# ── 3. Ensure package structure ─────────────────────────────────────────────────
[ -f "__init__.py" ] || touch "__init__.py"

# ── 4. Deploy ────────────────────────────────────────────────────────────────────
echo "Packaging and deploying to AgentCore Runtime..."
agentcore deploy

echo ""
echo "── Next steps ────────────────────────────────────────────────────────────"
echo "1. Copy the runtime ARN above into agents/concierge/setup_agent.py"
echo "   under toolConfigurations[].mcpServer.endpoint"
echo "2. Re-run: python agents/concierge/setup_agent.py"
echo "   (this registers the tool on your Connect AI agent)"
echo "3. To attach the runtime to the AgentCore Gateway, set the"
echo "   AGENTCORE_GATEWAY_ARN env var and configure it in the Connect"
echo "   AI agent designer under Integrations → Add MCP server."
