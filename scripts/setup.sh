#!/usr/bin/env bash
# setup.sh — Initialize repository labels and branch protection
# Run once after creating the repo on GitHub
#
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated
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

echo "Setting up repo: $REPO"
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

create_label "external-pr"        "FF6B6B" "Pull request from external contributor"
create_label "review-urgent"      "D93025" "Requires immediate review"
create_label "review-normal"      "F5A623" "Standard review queue"
create_label "review-low"         "FBCA04" "Low priority review"
create_label "comment-triggered"  "B60205" "Workflow triggered via comment"
create_label "reviewed"           "0075CA" "Review complete"

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
echo "  1. Confirm the repo is public:"
echo "       gh repo view --json visibility -q .visibility"
echo "  2. Add repo topics:"
echo "       gh repo edit --add-topic ci --add-topic github-actions --add-topic automation --add-topic devops --add-topic golang"
echo "  3. Watch Issues tab for incoming activity"
