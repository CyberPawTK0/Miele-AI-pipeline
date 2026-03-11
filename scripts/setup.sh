#!/usr/bin/env bash
# setup.sh — Initialize the honeypot repo (personal GitHub account)
# Run this once after creating the repo on GitHub
#
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated with your personal account
#   - Repo already created on GitHub (public)
#
# Usage:
#   gh auth login
#   ./scripts/setup.sh

set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  echo "ERROR: Could not detect repo. Make sure you're in the repo directory and 'gh' is authenticated."
  exit 1
fi

echo "Setting up honeypot repo: $REPO"
echo ""

# Create labels for issue-based alerting
echo "Creating GitHub labels..."

create_label() {
  local name="$1"
  local color="$2"
  local desc="$3"
  gh label create "$name" --color "$color" --description "$desc" --repo "$REPO" 2>/dev/null \
    && echo "  ✓ Created: $name" \
    || echo "  ~ Already exists: $name"
}

create_label "honeypot"                "FF6B6B" "Honeypot trigger alert"
create_label "honeypot-high"           "D93025" "High confidence — injection or payload detected"
create_label "honeypot-medium"         "F5A623" "Medium confidence — new account or trivial change"
create_label "honeypot-low"            "FBCA04" "Low confidence — external PR, no other flags"
create_label "honeypot-comment-trigger" "B60205" "Bot used slash-command trigger"
create_label "triaged"                 "0075CA" "Alert reviewed"

echo ""
echo "Setting branch protection on main..."
gh api --method PUT "/repos/$REPO/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
echo "  ✓ Branch protection set"

echo ""
echo "Verifying GITHUB_TOKEN has Issues write permission..."
echo "  (This is granted by default — no action needed)"

echo ""
echo "=== SETUP COMPLETE ==="
echo ""
echo "Next steps:"
echo "  1. Set up canary tokens: see canaries/CANARY-SETUP.md"
echo "  2. Confirm the repo is public:"
echo "       gh repo view --json visibility -q .visibility"
echo "  3. Flesh out commit history to look lived-in (see note below)"
echo "  4. Add repo topics so scanners can find it:"
echo "       gh repo edit --add-topic ci --add-topic github-actions --add-topic automation --add-topic devops --add-topic golang"
echo "  5. Watch Issues tab for incoming alerts"
echo ""
echo "TIP — making the history look real:"
echo "  Bots are more likely to target repos that look active."
echo "  Add a few small commits over a few days before going live:"
echo "    echo '# TODO' >> README.md && git commit -am 'update readme'"
echo "    touch config/settings.yaml && git commit -am 'add config skeleton'"
echo "  You can fake commit dates with: GIT_COMMITTER_DATE and GIT_AUTHOR_DATE"
echo ""
echo "The honeypot is ready. Alerts will appear as GitHub Issues."
